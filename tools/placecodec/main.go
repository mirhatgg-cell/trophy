package main

import (
	"bufio"
	"compress/gzip"
	"crypto/sha256"
	"encoding/json"
	"flag"
	"fmt"
	"github.com/robloxapi/rbxfile"
	"github.com/robloxapi/rbxfile/rbxl"
	"github.com/robloxapi/rbxfile/rbxlx"
	"io"
	"os"
	"strings"
)

type Record struct {
	I int                          `json:"i"`
	P int                          `json:"p"`
	C string                       `json:"c"`
	N string                       `json:"n"`
	V map[string][]json.RawMessage `json:"v"`
	B []json.RawMessage            `json:"b"`
}

func must(e error) {
	if e != nil {
		panic(e)
	}
}
func ns(b json.RawMessage) []float64 { var a []float64; must(json.Unmarshal(b, &a)); return a }
func n(b json.RawMessage) float64    { var a float64; must(json.Unmarshal(b, &a)); return a }
func s(b json.RawMessage) string     { var a string; must(json.Unmarshal(b, &a)); return a }
func boolean(b json.RawMessage) bool { var a bool; must(json.Unmarshal(b, &a)); return a }
func v3(a []float64) rbxfile.ValueVector3 {
	return rbxfile.ValueVector3{X: float32(a[0]), Y: float32(a[1]), Z: float32(a[2])}
}
func scene(path string) *rbxfile.Root {
	f, e := os.Open(path)
	must(e)
	defer f.Close()
	z, e := gzip.NewReader(f)
	must(e)
	defer z.Close()
	scan := bufio.NewScanner(z)
	scan.Buffer(make([]byte, 1<<20), 16<<20)
	root := rbxfile.NewRoot()
	items := map[int]*rbxfile.Instance{}
	type Ref struct {
		o  *rbxfile.Instance
		k  string
		id int
	}
	refs := []Ref{}
	for scan.Scan() {
		var r Record
		must(json.Unmarshal(scan.Bytes(), &r))
		o := rbxfile.NewInstance(r.C)
		o.Properties["Name"] = rbxfile.ValueString(r.N)
		items[r.I] = o
		if r.P == 0 {
			root.Instances = append(root.Instances, o)
			o.IsService = true
		} else {
			p := items[r.P]
			if p == nil {
				panic("missing parent")
			}
			p.Children = append(p.Children, o)
		}
		if len(r.B) > 0 {
			size, pos, col, rot := ns(r.B[0]), ns(r.B[1]), ns(r.B[2]), ns(r.B[4])
			var cf rbxfile.ValueCFrame
			cf.Position = v3(pos)
			for i, v := range rot {
				cf.Rotation[i] = float32(v)
			}
			o.Properties["size"] = v3(size)
			o.Properties["CFrame"] = cf
			o.Properties["Color3uint8"] = rbxfile.ValueColor3uint8{R: uint8(col[0]), G: uint8(col[1]), B: uint8(col[2])}
			o.Properties["Material"] = rbxfile.ValueToken(n(r.B[3]))
			o.Properties["Anchored"] = rbxfile.ValueBool(true)
			o.Properties["CanCollide"] = rbxfile.ValueBool(boolean(r.B[5]))
			o.Properties["CanQuery"] = rbxfile.ValueBool(boolean(r.B[5]))
			o.Properties["CanTouch"] = rbxfile.ValueBool(false)
			o.Properties["Transparency"] = rbxfile.ValueFloat(n(r.B[6]))
			o.Properties["shape"] = rbxfile.ValueToken(n(r.B[7]))
			o.Properties["CastShadow"] = rbxfile.ValueBool(boolean(r.B[8]))
			o.Properties["TopSurface"] = rbxfile.ValueToken(0)
			o.Properties["BottomSurface"] = rbxfile.ValueToken(0)
		}
		for k, pair := range r.V {
			typ, b := s(pair[0]), pair[1]
			switch typ {
			case "String":
				o.Properties[k] = rbxfile.ValueString(s(b))
			case "ProtectedString":
				o.Properties[k] = rbxfile.ValueProtectedString(s(b))
			case "Bool":
				o.Properties[k] = rbxfile.ValueBool(boolean(b))
			case "Int":
				o.Properties[k] = rbxfile.ValueInt(n(b))
			case "Float":
				o.Properties[k] = rbxfile.ValueFloat(n(b))
			case "Token":
				o.Properties[k] = rbxfile.ValueToken(n(b))
			case "Vector3":
				o.Properties[k] = v3(ns(b))
			case "Color3":
				a := ns(b)
				o.Properties[k] = rbxfile.ValueColor3{R: float32(a[0]), G: float32(a[1]), B: float32(a[2])}
			case "UDim2":
				a := ns(b)
				o.Properties[k] = rbxfile.ValueUDim2{X: rbxfile.ValueUDim{Scale: float32(a[0]), Offset: int32(a[1])}, Y: rbxfile.ValueUDim{Scale: float32(a[2]), Offset: int32(a[3])}}
			case "Ref":
				refs = append(refs, Ref{o, k, int(n(b))})
			default:
				panic("unknown type " + typ)
			}
		}
	}
	must(scan.Err())
	for _, r := range refs {
		if items[r.id] == nil {
			panic("bad reference")
		}
		r.o.Properties[r.k] = rbxfile.ValueReference{Instance: items[r.id]}
	}
	return root
}
func name(o *rbxfile.Instance) string {
	if v, ok := o.Properties["Name"].(rbxfile.ValueString); ok {
		return string(v)
	}
	return o.ClassName
}

type Collider struct {
	Name     string               `json:"name"`
	Size     rbxfile.ValueVector3 `json:"size"`
	Position rbxfile.ValueVector3 `json:"position"`
	Rotation [9]float32           `json:"rotation"`
}
type Report struct {
	SourceHashes map[string]string `json:"source_sha256"`
	Collision    []Collider        `json:"collision_geometry"`
	Parts        int               `json:"parts"`
	Architecture int               `json:"architecture_parts"`
	Trophies     map[string]int    `json:"trophy_parts"`
	Bodies       map[string]int    `json:"trophy_body_parts"`
	Colliders    int               `json:"colliders"`
	Scripts      int               `json:"scripts"`
}

func inspect(root *rbxfile.Root) Report {
	r := Report{SourceHashes: map[string]string{}, Trophies: map[string]int{}, Bodies: map[string]int{}}
	var walk func(*rbxfile.Instance, bool, string, bool)
	walk = func(o *rbxfile.Instance, museum bool, trophy string, body bool) {
		id := name(o)
		if id == "MuseumWorld" {
			museum = true
		}
		if strings.HasPrefix(id, "Exhibit_") {
			trophy = id
			r.Trophies[id] = 0
			r.Bodies[id] = 0
		}
		if id == "Body" {
			body = true
		}
		if o.ClassName == "Part" || o.ClassName == "SpawnLocation" || o.ClassName == "WedgePart" {
			r.Parts++
			if museum && trophy == "" {
				r.Architecture++
			}
			if trophy != "" {
				r.Trophies[trophy]++
				if body {
					r.Bodies[trophy]++
				}
			}
			if c, ok := o.Properties["CanCollide"].(rbxfile.ValueBool); ok && bool(c) {
				r.Colliders++
				cf, _ := o.Properties["CFrame"].(rbxfile.ValueCFrame)
				size, _ := o.Properties["size"].(rbxfile.ValueVector3)
				r.Collision = append(r.Collision, Collider{name(o), size, cf.Position, cf.Rotation})
			}
		}
		if o.ClassName == "Script" || o.ClassName == "LocalScript" || o.ClassName == "ModuleScript" {
			r.Scripts++
			switch source := o.Properties["Source"].(type) {
			case rbxfile.ValueProtectedString:
				r.SourceHashes[name(o)] = fmt.Sprintf("%x", sha256.Sum256([]byte(source)))
			case rbxfile.ValueString:
				r.SourceHashes[name(o)] = fmt.Sprintf("%x", sha256.Sum256([]byte(source)))
			}
		}
		for _, c := range o.Children {
			walk(c, museum, trophy, body)
		}
	}
	for _, o := range root.Instances {
		walk(o, false, "", false)
	}
	return r
}
func main() {
	input := flag.String("input", "", "gzip JSONL")
	output := flag.String("output", "", "rbxl")
	read := flag.String("read", "", "independent readback")
	xml := flag.String("xml", "", "optional XML or XML.gz")
	rp := flag.String("report", "", "JSON report")
	flag.Parse()
	var root *rbxfile.Root
	if *read != "" {
		f, e := os.Open(*read)
		must(e)
		defer f.Close()
		var warn, err error
		root, warn, err = (rbxl.Decoder{}).Decode(f)
		must(err)
		if warn != nil {
			fmt.Fprintln(os.Stderr, warn)
		}
	} else {
		root = scene(*input)
		if *output != "" {
			f, e := os.Create(*output)
			must(e)
			warn, e := (rbxl.Encoder{Mode: rbxl.Place}).Encode(f, root)
			must(e)
			must(f.Close())
			if warn != nil {
				fmt.Fprintln(os.Stderr, warn)
			}
		}
		if *xml != "" {
			f, e := os.Create(*xml)
			must(e)
			var w io.Writer = f
			var z *gzip.Writer
			if strings.HasSuffix(*xml, ".gz") {
				z = gzip.NewWriter(f)
				w = z
			}
			if strings.HasSuffix(*xml, ".gz") {
				must(streamXML(w, root))
			} else {
				warn, e := (rbxlx.Encoder{Indent: ""}).Encode(w, root)
				must(e)
				if warn != nil {
					fmt.Fprintln(os.Stderr, warn)
				}
			}
			if z != nil {
				must(z.Close())
			}
			must(f.Close())
		}
	}
	r := inspect(root)
	b, e := json.MarshalIndent(r, "", "  ")
	must(e)
	if *rp != "" {
		must(os.WriteFile(*rp, append(b, '\n'), 0644))
	}
	fmt.Printf("Verified %d Parts; architecture=%d; trophies=%d; colliders=%d; scripts=%d\n", r.Parts, r.Architecture, len(r.Trophies), r.Colliders, r.Scripts)
}

package main

import (
	"encoding/xml"
	"fmt"
	"github.com/robloxapi/rbxfile"
	"io"
	"sort"
	"strconv"
)

// Stream the large XML archive without constructing a second half-million-node DOM.
func streamXML(w io.Writer, root *rbxfile.Root) error {
	e := xml.NewEncoder(w)
	if _, err := io.WriteString(w, xml.Header); err != nil {
		return err
	}
	refs := map[*rbxfile.Instance]string{}
	var assign func(*rbxfile.Instance)
	assign = func(o *rbxfile.Instance) {
		refs[o] = fmt.Sprintf("RBX%08d", len(refs)+1)
		for _, c := range o.Children {
			assign(c)
		}
	}
	for _, o := range root.Instances {
		assign(o)
	}
	var err error
	start := func(tag string, attributes ...xml.Attr) {
		if err == nil {
			err = e.EncodeToken(xml.StartElement{Name: xml.Name{Local: tag}, Attr: attributes})
		}
	}
	end := func(tag string) {
		if err == nil {
			err = e.EncodeToken(xml.EndElement{Name: xml.Name{Local: tag}})
		}
	}
	text := func(value string) {
		if err == nil {
			err = e.EncodeToken(xml.CharData(value))
		}
	}
	scalar := func(tag, key, value string) {
		if key != "" {
			start(tag, xml.Attr{Name: xml.Name{Local: "name"}, Value: key})
		} else {
			start(tag)
		}
		text(value)
		end(tag)
	}
	f := func(v float32) string { return strconv.FormatFloat(float64(v), 'g', -1, 32) }
	start("roblox", xml.Attr{Name: xml.Name{Local: "version"}, Value: "4"})
	scalar("External", "", "null")
	scalar("External", "", "nil")
	var walk func(*rbxfile.Instance)
	walk = func(o *rbxfile.Instance) {
		start("Item", xml.Attr{Name: xml.Name{Local: "class"}, Value: o.ClassName}, xml.Attr{Name: xml.Name{Local: "referent"}, Value: refs[o]})
		start("Properties")
		keys := make([]string, 0, len(o.Properties))
		for k := range o.Properties {
			keys = append(keys, k)
		}
		sort.Strings(keys)
		for _, k := range keys {
			switch v := o.Properties[k].(type) {
			case rbxfile.ValueString:
				scalar("string", k, string(v))
			case rbxfile.ValueProtectedString:
				scalar("ProtectedString", k, string(v))
			case rbxfile.ValueBool:
				scalar("bool", k, strconv.FormatBool(bool(v)))
			case rbxfile.ValueInt:
				scalar("int", k, strconv.FormatInt(int64(v), 10))
			case rbxfile.ValueFloat:
				scalar("float", k, f(float32(v)))
			case rbxfile.ValueToken:
				scalar("token", k, strconv.FormatUint(uint64(v), 10))
			case rbxfile.ValueColor3uint8:
				scalar("Color3uint8", k, strconv.FormatUint(0xff000000|uint64(v.R)<<16|uint64(v.G)<<8|uint64(v.B), 10))
			case rbxfile.ValueReference:
				r := "null"
				if v.Instance != nil {
					r = refs[v.Instance]
				}
				scalar("Ref", k, r)
			case rbxfile.ValueVector3:
				start("Vector3", xml.Attr{Name: xml.Name{Local: "name"}, Value: k})
				scalar("X", "", f(v.X))
				scalar("Y", "", f(v.Y))
				scalar("Z", "", f(v.Z))
				end("Vector3")
			case rbxfile.ValueColor3:
				start("Color3", xml.Attr{Name: xml.Name{Local: "name"}, Value: k})
				scalar("R", "", f(v.R))
				scalar("G", "", f(v.G))
				scalar("B", "", f(v.B))
				end("Color3")
			case rbxfile.ValueCFrame:
				start("CoordinateFrame", xml.Attr{Name: xml.Name{Local: "name"}, Value: k})
				scalar("X", "", f(v.Position.X))
				scalar("Y", "", f(v.Position.Y))
				scalar("Z", "", f(v.Position.Z))
				for i, q := range v.Rotation {
					scalar(fmt.Sprintf("R%d%d", i/3, i%3), "", f(q))
				}
				end("CoordinateFrame")
			case rbxfile.ValueUDim2:
				start("UDim2", xml.Attr{Name: xml.Name{Local: "name"}, Value: k})
				scalar("XS", "", f(v.X.Scale))
				scalar("XO", "", strconv.FormatInt(int64(v.X.Offset), 10))
				scalar("YS", "", f(v.Y.Scale))
				scalar("YO", "", strconv.FormatInt(int64(v.Y.Offset), 10))
				end("UDim2")
			default:
				if err == nil {
					err = fmt.Errorf("unsupported XML value %T for %s", v, k)
				}
			}
		}
		end("Properties")
		for _, c := range o.Children {
			walk(c)
		}
		end("Item")
	}
	for _, o := range root.Instances {
		walk(o)
	}
	end("roblox")
	if err != nil {
		return err
	}
	return e.Flush()
}

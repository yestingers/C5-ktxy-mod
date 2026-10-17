// Uses the installed Nexus Buddy/Firaxis APIs, preserving the stock skeleton and shader.
using System;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Collections.Generic;
using System.Web.Script.Serialization;
using Firaxis.Framework;
using Firaxis.Framework.Granny;
using NexusBuddy.GrannyWrappers;
using NexusBuddy.GrannyInfos;
class ConvertGameModel {
 [STAThread] static unsafe int Main(string[] args) {
  try {
   Context.Add(new VirtualSpace());var ctx=new GrannyContext();Context.Add(ctx);Context.Add(new ProjectConfig());
   ctx.LoadStringDatabase(args[0]);
   var original=ctx.LoadGrannyFile(args[1]);
   var referenceBones=original.Models[0].Skeleton.Bones.Select(b=>b.Name).ToArray();
   var asm=Assembly.LoadFrom(Path.Combine(AppDomain.CurrentDomain.BaseDirectory,"NexusBuddy2.exe"));
   var importer=asm.GetType("NexusBuddy.FileOps.BR2Importer");
   var info=importer.GetMethod("loadModelInfo",BindingFlags.Static|BindingFlags.NonPublic).Invoke(null,new object[]{args[2]});
   importer.GetMethod("doBoneBindings",BindingFlags.Static|BindingFlags.NonPublic|BindingFlags.Public).Invoke(null,new object[]{info});
   var meshes=(List<GrannyMeshInfo>)info.GetType().GetField("meshBindings").GetValue(info);
   if(meshes.Count!=1)throw new Exception("Unexpected mesh count");
   var templatePath=Path.Combine(Path.GetDirectoryName(args[2]),"unit_template.gr2");
   using(var input=asm.GetManifestResourceStream("NexusBuddy.GrannyTemplates.model_template.gr2"))
   using(var output=File.Create(templatePath)) input.CopyTo(output);
   var template=ctx.LoadGrannyFile(Path.GetFullPath(templatePath));
   var newMesh=template.Models[0].MeshBindings[0];
   var meshWrap=new GrannyMeshWrapper(newMesh);
   meshWrap.writeMeshInfo(meshes[0],false,false);
   // Use the original game's UnitShader_Skinned material for the new mesh.
   var oldWrap=new GrannyMeshWrapper(original.Meshes[0]);
   *(int*)meshWrap.getMaterialBindingsPtr()=*(int*)oldWrap.getMaterialBindingsPtr();
   meshWrap.setNumMaterialBindings(1);
   var modelWrap=new GrannyModelWrapper(original.Models[0]);
   modelWrap.setNumMeshBindings(0);original.Models[0].MeshBindings.Clear();
   importer.GetMethod("doAppendMeshBinding",BindingFlags.Static|BindingFlags.Public).Invoke(null,new object[]{ctx,original,template,0});
   var fileWrap=new GrannyFileWrapper(original);fileWrap.setNumMeshes(0);fileWrap.setNumTriTopologies(0);fileWrap.setNumVertexDatas(0);original.Meshes.Clear();original.AddMeshReference(newMesh);
   var mat=original.Materials[0];new GrannyMaterialWrapper(mat).setName("Cartethyia_Unit");
   var parameters=mat.FindParameterSet("UnitShaderTextures");
   parameters.SetParameterValue("BaseTextureMap","Cartethyia_Unit_DIFF.dds");
   parameters.SetParameterValue("SREFMap","Cartethyia_Unit_SREF.dds");
   mat.AlphaMode=1;mat.AlphaRef=64;
   original.Filename=Path.GetFullPath(args[3]);original.Source="Tool";original.Save();
   // Reopen a new pathname to avoid a library cache masking serialization errors.
   var verify=Path.Combine(Path.GetDirectoryName(args[3]),"verify.tmp.gr2");File.Copy(args[3],verify,true);
   var file=ctx.LoadGrannyFile(Path.GetFullPath(verify));
   var mesh=new GrannyMeshWrapper(file.Meshes[0]).getMeshInfo();
   var bones=file.Models[0].Skeleton.Bones.Select(b=>b.Name).ToArray();
   var bad=mesh.vertices.Count(v=>v.boneWeights.Sum()!=255 || Enumerable.Range(0,4).Any(i=>v.boneWeights[i]>0 && v.boneIndices[i]>=mesh.boneBindings.Count));
   var savedParams=file.Materials[0].FindParameterSet("UnitShaderTextures");
   var report=new {vertices=mesh.vertices.Count,triangles=mesh.triangles.Count,bone_names=bones,reference_bone_names=referenceBones,
    materials=file.Materials.Select(m=>m.Name).ToArray(),mesh_materials=file.Meshes[0].MaterialBindings.Select(m=>m.Name).ToArray(),
    textures=new[]{(string)savedParams.GetParameterValue("BaseTextureMap"),(string)savedParams.GetParameterValue("SREFMap")},
    model_sha256=BitConverter.ToString(System.Security.Cryptography.SHA256.Create().ComputeHash(File.ReadAllBytes(args[3]))).Replace("-","").ToLowerInvariant(),
    unbound_bones=mesh.boneBindings.Where(n=>!bones.Contains(n)).ToArray(),invalid_weight_count=bad};
   File.WriteAllText(Path.ChangeExtension(args[3],"audit.json"),new JavaScriptSerializer().Serialize(report));
   Console.WriteLine(new JavaScriptSerializer().Serialize(report));
   if(bad>0 || report.unbound_bones.Length>0)throw new Exception("Readback validation failed");
   return 0;
  }catch(Exception e){Console.Error.WriteLine(e);return 1;}
 }
}

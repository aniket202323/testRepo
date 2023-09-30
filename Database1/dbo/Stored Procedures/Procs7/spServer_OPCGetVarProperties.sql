CREATE PROCEDURE dbo.spServer_OPCGetVarProperties
AS
select ap.OPC_Type_Id     as Type,
       c.Prop_Class_Desc  as Class,
       p.Prop_Id          as Property,
       p.HDA_Prop_Id      as HDA_Property,
       p.Prop_Name        as PropName,
       p.Prop_Description as PropDesc,
       t.Data_Type_Desc   as DataType,
       case p.Writeable when 1 then 'Yes' else 'No' end as Writeable
  from      OPC_available_properties as ap
       join OPC_Property             as p  on ap.Prop_Id = p.Prop_Id
       join OPC_Class                as c  on ap.Prop_Class_id = c.Prop_Class_Id
       join Data_Type                as t  on p.Prop_Data_Type = t.Data_Type_Id

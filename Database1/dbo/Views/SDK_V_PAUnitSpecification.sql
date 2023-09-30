CREATE view SDK_V_PAUnitSpecification
as
select
Var_Specs.VS_Id as Id,
Var_Specs.Comment_Id as CommentId,
Var_Specs.Effective_Date as EffectiveDate,
Var_Specs.Expiration_Date as ExpirationDate,
Var_Specs.L_Entry as LEL,
Var_Specs.L_Reject as LRL,
Var_Specs.L_User as LUL,
Var_Specs.L_Warning as LWL,
Var_Specs.U_Entry as UEL,
Var_Specs.U_Reject as URL,
Var_Specs.U_User as UUL,
Var_Specs.U_Warning as UWL,
Products.Prod_Code as ProductCode,
Products.Prod_Desc as ProductDescription,
Var_Specs.Test_Freq as TestingFrequency,
Var_Specs.Target as TGT,
Variables.Var_Desc as Variable,
Prod_Units_Base.PU_Desc as ProductionUnit,
Prod_Lines_Base.PL_Desc as ProductionLine,
Variables.Test_Name as TestName,
Var_Specs.Esignature_Level as ESignatureLevelId,
Var_Specs.Prod_Id as ProductId,
Prod_Units_Base.PU_Id as ProductionUnitId,
Var_Specs.Var_Id as VariableId,
Departments_Base.Dept_Desc as Department,
Prod_Lines_Base.Dept_Id as DepartmentId,
Prod_Units_Base.PL_Id as ProductionLineId,
Comments.Comment_Text as CommentText,
Var_Specs.U_Control as UCL,
Var_Specs.T_Control as TCL,
Var_Specs.L_Control as LCL,
ED_FieldType_ValidValues.Field_Desc as ESignatureLevel,
VarSigDesc.Field_Desc as VarESignatureLevel,
variables.Esignature_Level as VarESignatureLevelId,
Case When/**/.Var_Specs.Is_Defined & 1024 = 1024 Then 1 Else 0 End as OESignatureLevel,
Case When/**/.Var_Specs.Is_Defined & 8192 = 8192 Then 1 Else 0 End as OLCL,
Case When/**/.Var_Specs.Is_Defined & 1 = 1 Then 1 Else 0 End as OLEL,
Case When/**/.Var_Specs.Is_Defined & 2 = 2 Then 1 Else 0 End as OLRL,
Case When/**/.Var_Specs.Is_Defined & 8 = 8 Then 1 Else 0 End as OLUL,
Case When/**/.Var_Specs.Is_Defined & 4 = 4 Then 1 Else 0 End as OLWL,
Case When/**/.Var_Specs.Is_Defined & 16384 = 16384 Then 1 Else 0 End as OTCL,
Case When/**/.Var_Specs.Is_Defined & 512 = 512 Then 1 Else 0 End as OTestingFrequency,
Case When/**/.Var_Specs.Is_Defined & 16 = 16 Then 1 Else 0 End as OTGT,
Case When/**/.Var_Specs.Is_Defined & 32768 = 32768 Then 1 Else 0 End as OUCL,
Case When/**/.Var_Specs.Is_Defined & 256 = 256 Then 1 Else 0 End as OUEL,
Case When/**/.Var_Specs.Is_Defined & 128 = 128 Then 1 Else 0 End as OURL,
Case When/**/.Var_Specs.Is_Defined & 32 = 32 Then 1 Else 0 End as OUUL,
Case When/**/.Var_Specs.Is_Defined & 64 = 64 Then 1 Else 0 End as OUWL,
var_specs.AS_Id as CentralSpecificationId
FROM Var_Specs 
JOIN Variables_Base as Variables   ON Variables.var_id = Var_Specs.var_id
JOIN Prod_Units_Base  ON Prod_Units_Base.Pu_Id = Variables.Pu_Id
JOIN Prod_Lines_Base  ON Prod_Lines_Base.PL_Id = Prod_Units_Base.PL_Id 
JOIN Departments_Base ON Departments_Base.Dept_Id = Prod_Lines_Base.Dept_Id
JOIN Products 	  ON Products.Prod_Id = Var_Specs.Prod_Id 
 left join ED_FieldType_ValidValues on ED_FieldType_ValidValues.ED_Field_Type_Id = 55 and ED_FieldType_ValidValues.Field_Id = Var_Specs.Esignature_Level
 left join ED_FieldType_ValidValues as VarSigDesc on VarSigDesc.ED_Field_Type_Id = 55 and VarSigDesc.Field_Id = Variables.Esignature_Level
LEFT JOIN Comments Comments on Comments.Comment_Id=var_specs.Comment_Id

CREATE view SDK_V_PACentralSpecification
as
select
Active_Specs.AS_Id as Id,
Product_Properties.Prop_Desc as ProductProperty,
Specifications.Spec_Desc as PropertySpecification,
Active_Specs.Comment_Id as CommentId,
Active_Specs.Effective_Date as EffectiveDate,
Active_Specs.Expiration_Date as ExpirationDate,
Active_Specs.L_Entry as LEL,
Active_Specs.L_Reject as LRL,
Active_Specs.L_User as LUL,
Active_Specs.L_Warning as LWL,
Active_Specs.U_Entry as UEL,
Active_Specs.U_Reject as URL,
Active_Specs.U_User as UUL,
Active_Specs.U_Warning as UWL,
Active_Specs.Test_Freq as TestingFrequency,
Active_Specs.Target as TGT,
Characteristics.Char_Desc as Characteristic,
Active_Specs.Char_Id as CharacteristicId,
Specifications.Prop_Id as ProductPropertyId,
Active_Specs.Spec_Id as PropertySpecificationId,
Comments.Comment_Text as CommentText,
Active_Specs.T_Control as TCL,
Active_Specs.U_Control as UCL,
Active_Specs.L_Control as LCL,
Active_Specs.Esignature_Level as ESignatureLevelId,
ED_FieldType_ValidValues.Field_Desc as ESignatureLevel,
Case When/**/.Active_Specs.Is_Defined & 16384 = 16384 Then 1 Else 0 End as OTCL,
Case When/**/.Active_Specs.Is_Defined & 16 = 16 Then 1 Else 0 End as OTGT,
Case When/**/.Active_Specs.Is_Defined & 32768 = 32768 Then 1 Else 0 End as OUCL,
Case When/**/.Active_Specs.Is_Defined & 256 = 256 Then 1 Else 0 End as OUEL,
Case When/**/.Active_Specs.Is_Defined & 128 = 128 Then 1 Else 0 End as OURL,
Case When/**/.Active_Specs.Is_Defined & 32 = 32 Then 1 Else 0 End as OUUL,
Case When/**/.Active_Specs.Is_Defined & 64 = 64 Then 1 Else 0 End as OUWL,
Case When/**/.Active_Specs.Is_Defined & 512 = 512 Then 1 Else 0 End as OTestingFrequency,
Case When/**/.Active_Specs.Is_Defined & 8192 = 8192 Then 1 Else 0 End as OLCL,
Case When/**/.Active_Specs.Is_Defined & 1 = 1 Then 1 Else 0 End as OLEL,
Case When/**/.Active_Specs.Is_Defined & 2 = 2 Then 1 Else 0 End as OLRL,
Case When/**/.Active_Specs.Is_Defined & 8 = 8 Then 1 Else 0 End as OLUL,
Case When/**/.Active_Specs.Is_Defined & 4 = 4 Then 1 Else 0 End as OLWL,
Case When/**/.Active_Specs.Is_Defined & 1024 = 1024 Then 1 Else 0 End as OESignatureLevel
FROM Product_Properties
 JOIN Specifications ON Specifications.Prop_Id = Product_Properties.Prop_Id
 JOIN Active_Specs ON Active_Specs.Spec_Id = Specifications.Spec_Id
 JOIN Characteristics ON Active_Specs.Char_Id = Characteristics.Char_Id
 left join ED_FieldType_ValidValues on ED_FieldType_ValidValues.ED_Field_Type_Id = 55 and ED_FieldType_ValidValues.Field_Id = Active_Specs.ESignature_Level
LEFT JOIN Comments Comments on Comments.Comment_Id=active_specs.Comment_Id

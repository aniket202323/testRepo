Create Procedure dbo.spEMDT_GetModelInfo
@User_Id int
 AS
Select ST_Id,ST_Desc, 'IsDefault' = case When  ST_Id =  12 then 1 else 0 End
 From Sampling_type Where ST_Id  in (2,12,14)
Select ED_Attribute_Id,Attribute_Desc, 'IsDefault' = case When  ED_Attribute_Id =  1 then 1 else 0 End 
 	 From ed_attributes

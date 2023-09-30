Create Procedure dbo.spEMCO_EditLineSpec
@Order_Spec_Id int,
@Spec_Desc nVarChar(100),
@Data_Type_Id int,
@Spec_Precision int,
@U_Limit nVarChar(25),
@Target nVarChar(25),
@L_Limit nVarChar(25),
@User_Id int
AS
  DECLARE @Insert_Id int 
 INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id, 'spEMCO_EditLineSpec' ,
 	    convert(nVarChar(10), @Order_Spec_Id) +  "," + @Spec_Desc +  "," + convert(nVarChar(10), @Data_Type_Id) +  "," + convert(nVarChar(10), @Spec_Precision) +  "," + @U_Limit +  "," + @Target +  "," + @L_Limit
                 +  "," + Convert(nVarChar(10),@User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
update Customer_Order_Line_Specs
set 	 Spec_Desc = @Spec_Desc,
 	 Data_Type_Id = @Data_Type_Id,
 	 Spec_Precision = @Spec_Precision,
 	 U_Limit = @U_Limit,
 	 Target = @Target,
 	 L_Limit = @L_Limit
where Order_Spec_Id = @Order_Spec_Id 
UPDATE Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
WHERE Audit_Trail_Id = @Insert_Id

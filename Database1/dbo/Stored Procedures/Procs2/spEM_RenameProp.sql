CREATE PROCEDURE dbo.spEM_RenameProp
  @Prop_Id   int,
  @Prop_Desc nvarchar(50),
  @User_Id int
  AS
  DECLARE @Insert_Id integer
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_RenameProp',
                Convert(nVarChar(10),@Prop_Id) + ','  + 
                @Prop_Desc + ','  + 
 	  	 Convert(nVarChar(10),@User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
  --
  -- Return Code: 0 = Success. 
  --
 	   If (@@Options & 512) = 0
 	  	 Update Product_Properties Set Prop_Desc_Global = @Prop_Desc Where Prop_Id = @Prop_Id
     Else
 	  	 Update Product_Properties Set Prop_Desc_Local = @Prop_Desc Where Prop_Id = @Prop_Id
 	  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
 	  	  WHERE Audit_Trail_Id = @Insert_Id
  RETURN(0)

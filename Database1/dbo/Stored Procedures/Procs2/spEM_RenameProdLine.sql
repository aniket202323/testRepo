CREATE PROCEDURE dbo.spEM_RenameProdLine
  @PL_Id       int,
  @Description nvarchar(50),
  @User_Id int
 AS
  DECLARE @Insert_Id integer,@Alias nVarChar(100), @AliasCompressed nVarChar(100), @OldDesc nVarChar(100)
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
  	  VALUES (1,@User_Id,'spEM_RenameProdLine',Convert(nVarChar(10),@PL_Id) + ','  + 
                @Description + ','  + Convert(nVarChar(10),@User_Id),dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
  --
  -- Return Codes:
  --
  --   0 = Success
  --
  SELECT @OldDesc = NULL 
   If (@@Options & 512) = 0
     Update Prod_Lines_Base Set PL_Desc_Global = @Description Where PL_Id = @PL_Id
 	 Else
 	 Begin
 	  	 --Always use Local for tag rename if its there
 	  	 SELECT @OldDesc = LTrim(RTrim(Replace(PL_Desc,' ',''))) from Prod_Lines where PL_ID = @PL_ID
 	  	 Update Prod_Lines_Base Set PL_Desc = @Description Where PL_Id = @PL_Id
 	 End
  /*LMA:  Add Logic to Update PL_Desc on Input_tag if User Renames PL_Desc
          but ONLY IF _LOCAL change OR not in MultiLingual Mode*/ 	 
  If @OldDesc is not NULL 
    Begin
      -- Sometimes the Alias isn't compressed. 
      SELECT @AliasCompressed = LTrim(RTrim(Replace(Alias,' ',''))), @Alias = Alias from historians where hist_id = -1
      -- Just in case the line and unit or variable are the same or contain similar characters
      SELECT @OldDesc = '\' + @OldDesc + '.', @Description = '\' + @Description + '.'
      Update Variables_Base 
        Set Input_tag = Replace(Input_Tag,@OldDesc, LTrim(RTrim(Replace(@Description,' ', ''))))
        Where Input_tag like '\\' + @AliasCompressed + @OldDesc + '%' 
           OR Input_tag like '\\' + @Alias + @OldDesc + '%' 
    End
  /*LMA*/ 	 
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
     WHERE Audit_Trail_Id = @Insert_Id
  RETURN(0)

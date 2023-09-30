CREATE PROCEDURE dbo.spEM_RenameProdUnit
  @PU_Id       int,
  @Description nvarchar(50),
  @User_Id int
 AS
  --
  DECLARE @Insert_Id integer, @OldDesc nVarChar(100), @Alias nVarchar (100), @AliasCompressed nVarChar(100), @LineDesc nVarChar(100)
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
  	  VALUES (1,@User_Id,'spEM_RenameProdUnit',Convert(nVarChar(10),@PU_Id) + ','  +  @Description + ','  + 
  	    	  Convert(nVarChar(10),@User_Id),dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
  SELECT @OldDesc = NULL 
  BEGIN TRANSACTION
     If (@@Options & 512) = 0
  	      Update Prod_Units_Base Set PU_Desc_Global = @Description Where PU_Id = @PU_Id
     Else
       Begin
         SELECT @OldDesc = LTrim(RTrim(Replace(PU_Desc,' ',''))) from Prod_Units_Base where PU_ID = @PU_ID
         Update Prod_Units_Base Set PU_Desc = @Description Where PU_Id = @PU_Id
         --Always use Local for tag rename if its there, it will be eqaul to the PU_Desc 
         SELECT @LineDesc = LTrim(RTrim(Replace(PL_Desc,' ',''))) from Prod_Lines where PL_ID in (SELECT PL_ID from Prod_Units_Base where @PU_ID = pu_id)
       End
   	  
  /*LMA:  Add Logic to Update PU_Desc on Input_tag if User Renames PU_Desc
          but ONLY IF _LOCAL change OR not in MultiLingual Mode*/ 	 
  If @OldDesc is not NULL 
    Begin
      -- Sometimes the Alias isn't compressed. 
      SELECT @AliasCompressed = LTrim(RTrim(Replace(Alias,' ',''))), @Alias = Alias from historians where hist_id = -1
      -- Just in case the line and unit or variable are the same or contain similar characters
      SELECT @OldDesc = '.' + @OldDesc + '.', @Description = '.' + @Description + '.'
      Update Variables_Base 
        Set Input_tag = Replace(Input_Tag,@OldDesc, LTrim(RTrim(Replace(@Description,' ', ''))))
        Where Input_tag like '\\' + @AliasCompressed + '\' + @LineDesc + @OldDesc + '%' 
           OR Input_tag like '\\' + @Alias + '\' + @LineDesc + @OldDesc + '%' 
    End
  /*LMA*/ 	 
  IF @@ERROR <> 0 
    BEGIN
      ROLLBACK TRANSACTION 
      RETURN (1)
    END
  COMMIT TRANSACTION   
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
     WHERE Audit_Trail_Id = @Insert_Id
  RETURN(0)

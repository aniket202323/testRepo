CREATE PROCEDURE dbo.spEM_CreatebinaryId
  @Sheet_Id 	  	  	 Int,
  @Option_Id        Int,
  @User_Id 	  	  	 Int,
  @Bin_Id         	 Int OUTPUT
  AS
  --
  -- Return Codes:
  --
  --   0 = Success
  --   1 = Can't create characteristic.
  --
DECLARE @Insert_Id integer,
 	  	 @Desc nvarchar(50),
 	  	 @OptExists 	 Int
Insert into Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_CreatebinaryId',
                 Convert(nVarChar(10),@Sheet_Id) + ',' + convert(nVarChar(10), @Option_Id) + ','  + Convert(nVarChar(10), @User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  select @Insert_Id = Scope_Identity()
  Select @Bin_Id = Null
  Select @Desc = '[' + convert(nVarChar(10),max(Binary_Id) + 1) + '] Barcode.exe' From Binaries
  Select @OptExists  = Null
  Select @OptExists  = Display_Option_Id  From Sheet_Display_Options Where Sheet_Id = @Sheet_Id and Display_Option_Id = @Option_Id
  BEGIN TRANSACTION
 	 Insert Into Binaries (Binary_Desc) Values (@Desc)
   	 SELECT @Bin_Id = Scope_Identity()
  IF @Bin_Id IS NULL
    BEGIN
      ROLLBACK TRANSACTION
      Update  Audit_Trail set EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 1 where Audit_Trail_Id = @Insert_Id
      RETURN(1)
    END
  If @OptExists is null
 	 Insert Into Sheet_Display_Options (Sheet_Id,Display_Option_Id,Binary_Id) Values (@Sheet_Id,@Option_Id,@Bin_Id)
  Else
 	 Update Sheet_Display_Options set Binary_Id = @Bin_Id Where  Sheet_Id = @Sheet_Id and Display_Option_Id = @Option_Id
  COMMIT TRANSACTION
  Update  Audit_Trail set EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 0 ,Output_Parameters = convert(nVarChar(10),@Bin_Id)  where Audit_Trail_Id = @Insert_Id
  RETURN(0)

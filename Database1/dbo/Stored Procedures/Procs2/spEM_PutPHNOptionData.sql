CREATE PROCEDURE dbo.spEM_PutPHNOptionData
  @PHN_Id       int,
  @OptionId 	 Int,
  @Value 	  	 nvarchar(1000),
  @User_Id int
  AS
  --
  DECLARE @Insert_Id integer 
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_PutPHNOptionData',
        Convert(nVarChar(10),@PHN_Id) + ','  + 
 	  	 Convert(nVarChar(10),@OptionId) + ','  + 
 	  	 substring(@Value,1,200) + ','  + 
 	  	 Convert(nVarChar(10),@User_Id),dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
  If ltrim(rtrim(@value)) = '' or ltrim(rtrim(@value)) is null
    Delete From Historian_Option_Data where Hist_Id = @PHN_Id and Hist_Option_Id = @OptionId
  Else
    Begin
      Update Historian_Option_Data set value = @Value Where  Hist_Id = @PHN_Id and Hist_Option_Id = @OptionId
      If @@Rowcount = 0
        Insert Into Historian_Option_Data (Hist_Id,Hist_Option_Id,Value) Values (@PHN_Id,@OptionId,@Value)
    End
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
     WHERE Audit_Trail_Id = @Insert_Id
  RETURN(0)

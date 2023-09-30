CREATE PROCEDURE dbo.spEM_CreateScheduleStatus
  @Description  nvarchar(50),
  @User_Id int,
  @PP_Status_Id int OUTPUT
  AS
  --
  -- Return Codes:
  --
  --   0 = Success
  --   1 = Error: Can't create data type.
  --
DECLARE @Insert_Id integer ,@Sql nvarchar(1000)
Insert into Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_CreateScheduleStatus',
                 @Description + ','  + Convert(nVarChar(10), @User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
select @Insert_Id = Scope_Identity()
If Exists (select * from dbo.syscolumns where name = 'PP_Status_Desc_Local' and id =  object_id(N'[Production_Plan_Statuses]'))
 	 Select @Sql =  'INSERT INTO Production_Plan_Statuses(PP_Status_Desc_Local)'
Else
 	 Select @Sql =  'INSERT INTO Production_Plan_Statuses(PP_Status_Desc)'
Select @Sql = @Sql + ' VALUES(''' + replace(@Description,'''','''''') + ''')' 
Execute(@Sql)
SELECT @PP_Status_Id = PP_Status_Id FROM Production_Plan_Statuses WHERE PP_Status_Desc = @Description
IF @PP_Status_Id IS NULL
BEGIN
   Update  Audit_Trail set EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 1 where Audit_Trail_Id = @Insert_Id
   RETURN(1)
END
Update  Audit_Trail set EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 0,Output_Parameters = convert(nVarChar(10),@PP_Status_Id) where Audit_Trail_Id = @Insert_Id
  RETURN(0)

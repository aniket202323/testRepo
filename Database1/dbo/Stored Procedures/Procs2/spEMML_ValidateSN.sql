CREATE PROCEDURE dbo.spEMML_ValidateSN
@SN nVarChar(25),
@User_Id int,
@ValidSN bit OUTPUT
AS
Declare @Insert_Id int
INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEMML_ValidateSN',
             Convert(nVarChar(10),@User_Id), dbo.fnServer_CmnGetDate(getUTCdate()))
SELECT @Insert_Id = Scope_Identity()
Declare @SiteParamSN nvarchar(50)
select @SiteParamSN = Value from Site_Parameters
where Parm_Id = 22
if @SiteParamSN = @SN
  select @ValidSN = 1
else
  Begin
    select @ValidSN = 0
    if @SN = "D000002" and @SiteParamSN = "D000001"
      Begin
        update Site_Parameters set Value = @SN
        where Parm_Id = 22
        exec spEMML_ReSyncUsers @User_Id, 1
        select @ValidSN = 1
      End
  End
UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
WHERE Audit_Trail_Id = @Insert_Id

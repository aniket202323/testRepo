Create Procedure dbo.spEMFC_UpdateFTPActiveStatus
@FC_Id int,
@Is_Active tinyint,
@User_Id int
AS
  DECLARE @Insert_Id int 
 INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id, 'spEMFC_UpdateFTPActiveStatus' ,
                 convert(nVarChar(10), @FC_Id) + ',' + convert(nVarChar(10), @Is_Active) + ',' + Convert(nVarChar(10),@User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
update FTP_Config
set Is_Active = @Is_Active
where FC_Id = @FC_Id
UPDATE Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
WHERE Audit_Trail_Id = @Insert_Id

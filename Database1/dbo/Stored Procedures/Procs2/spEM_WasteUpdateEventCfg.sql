Create Procedure dbo.spEM_WasteUpdateEventCfg
@ECId int,
@ECDesc nvarchar(50),
@Option Int,
@UserId int
AS
declare @Id int, @Insert_Id int
Declare @EcvId INt
INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@UserId,'spEM_WasteUpdateEventCfg',
             Isnull(Convert(nVarChar(10),@ECId),'Null') + ','  + 
             Isnull(@ECDesc,'Null') + ','  + 
             Isnull(Convert(nVarChar(10),@Option),'Null') + ','  + 
             Convert(nVarChar(10),@UserId), dbo.fnServer_CmnGetDate(getUTCdate()))
SELECT @Insert_Id = Scope_Identity()
Update Event_Configuration set EC_Desc = @ECDesc Where EC_Id = @ECId
Select @EcvId = ecv_Id From event_Configuration_Data where  EC_Id = @ECId and ED_Field_Id = 2822
Update Event_Configuration_Values set Value = convert(nVarChar(10),@Option) where ecv_Id = @EcvId
UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
WHERE Audit_Trail_Id = @Insert_Id

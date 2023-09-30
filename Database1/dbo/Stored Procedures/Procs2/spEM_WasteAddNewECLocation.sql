/*
declare @ECVId Int
execute spEM_WasteAddNewECLocation 3146,2180,1,@ECVId OUTPUT
select @ECVId
*/
Create Procedure dbo.spEM_WasteAddNewECLocation
@ECID int, 
@LocationPUId int,
@UserId int,
@ECVId int OUTPUT
 AS 
Declare @Insert_Id int
INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@UserId,'spEM_WasteAddNewECLocation',
             Isnull(Convert(nVarChar(10),@ECID),'Null') + ','  + 
             Isnull(Convert(nVarChar(10),@LocationPUId),'Null') + ','  + 
             Convert(nVarChar(10),@UserId), dbo.fnServer_CmnGetDate(getUTCdate()))
SELECT @Insert_Id = Scope_Identity()
Declare @EDFieldId int
Select @EDFieldId = ED_Field_Id 
  From ED_Fields f
  JOIN Event_Configuration c on c.ED_Model_Id = f.ED_Model_Id and c.EC_id = @ECId
  Where  f.Field_Desc = 'FaultScript'
if @LocationPUId = 0 
  SELECT @LocationPUId = NULL
SELECT @ECVId = NULL 
SELECT @ECVId = ECV_Id
    FROM Event_Configuration_Data  d
    WHERE d.EC_Id = @ECId and d.Ed_Field_Id = @EDFieldId and PU_Id = @LocationPUId
if @ECVId is null 
  BEGIN
    Insert into Event_Configuration_Values (Value) Values(Null)
    Select @ECVId = IDENT_CURRENT('Event_Configuration_Values')
    Insert into Event_Configuration_Data (EC_Id, ED_Field_Id, Alias, PU_Id, ECV_Id)
      values (@ECID, @EDFieldId, Null, @LocationPUId, @ECVId)
  END
UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
WHERE Audit_Trail_Id = @Insert_Id

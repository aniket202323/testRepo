Create Procedure dbo.spEMEC_UpdatePriority
@EC_Id  	  	 int,
@Direction  	 int,
@User_Id  	 int
as
Declare @PUID Int,@MaxPri Int,@Id Int,@SwapECId Int,@OldPriority Int
Declare @Insert_Id int
INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEMEC_UpdatePriority',
             Convert(nVarChar(10),@EC_Id) + ','  + 
             Convert(nVarChar(10),@Direction) + ','  + 
             Convert(nVarChar(10),@User_Id), dbo.fnServer_CmnGetDate(getUTCdate()))
SELECT @Insert_Id = Scope_Identity()
Select @PUID = PU_Id from event_Configuration where EC_Id = @EC_Id
Select @MaxPri = Max(Priority) From Event_Configuration Where Is_Active = 1 and Priority is null and PU_Id = @PUID
Select @MaxPri = coalesce(@MaxPri,0)
/* Set all Prioritys first */ 
Update Event_Configuration set Priority = Null where Is_Active <> 1  and PU_Id = @PUID
If (Select Count(*) From Event_Configuration Where Is_Active = 1 and Priority is null and PU_Id = @PUID) > 0 
  Begin
 	 Declare Event_C Cursor For Select EC_Id  From Event_Configuration Where Is_Active = 1 and Priority is null and PU_Id = @PUID Order by EC_Id
 	 For Update
 	 Open Event_C
Event_C_Loop:
 	 Fetch Next from Event_C into @Id
 	 If @@Fetch_Status = 0
 	   Begin
 	  	 Select @MaxPri = @MaxPri + 1
 	  	 Update Event_Configuration set priority = @MaxPri where current of Event_C
 	  	 goto Event_C_Loop
 	   End
 	 Close Event_C
 	 Deallocate Event_C
  End
Select @MaxPri = Null
Select @MaxPri = Max(Priority) From Event_Configuration Where Is_Active = 1 and Priority is Not null and PU_Id = @PUID
Select @MaxPri = coalesce(@MaxPri,0)
/* Fix Out of order Priorities */ 
If (Select Count(*) From Event_Configuration Where Is_Active = 1 and Priority is Not null and PU_Id = @PUID) <> @MaxPri
BEGIN
 	 DECLARE @ActiveEC 	 TABLE (Currentid int Identity(1,1),ECID Int,Priority Int)
 	 INSERT INTO @ActiveEC (ECID,Priority)
 	  	 SELECT Ec_id,Priority
 	  	  	 From Event_Configuration  ec
 	  	  	 Left Join Ed_Models em on em.ED_Model_Id = ec.ED_Model_Id 
 	  	  	 Where ec.Is_Active = 1 and ec.PU_Id = @PUID 
 	  	  	 Order by ec.Priority,em.Model_Num
 	 UPDATE Event_Configuration SET Priority = Currentid 
 	  	 FROM Event_Configuration a
 	  	 JOIN @ActiveEC b on b.ECID = a.Ec_id 
 	  	 WHERE a.Priority <> Currentid
  END
ELSE
BEGIN
 	 Select @OldPriority = Priority from event_Configuration where EC_Id = @EC_Id
 	 If @Direction = 0 --Up
 	   Begin
 	  	 Select @SwapECId = Ec_Id from Event_Configuration Where Priority = @OldPriority - 1 And Is_Active = 1 and  PU_Id = @PUID 
 	  	 Update Event_Configuration set Priority = @OldPriority - 1 Where EC_Id = @EC_Id
 	  	 Update Event_Configuration set Priority = @OldPriority Where EC_Id = @SwapECId
 	   End
 	 Else --Down
 	   Begin
 	  	 Select @SwapECId = Ec_Id from Event_Configuration Where Priority = @OldPriority + 1 And Is_Active = 1 and  PU_Id = @PUID 
 	  	 Update Event_Configuration set Priority = @OldPriority + 1 Where EC_Id = @EC_Id
 	  	 Update Event_Configuration set Priority = @OldPriority Where EC_Id = @SwapECId
 	   End
END
UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
WHERE Audit_Trail_Id = @Insert_Id

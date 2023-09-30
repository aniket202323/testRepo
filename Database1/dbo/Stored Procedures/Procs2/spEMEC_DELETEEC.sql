CREATE Procedure dbo.spEMEC_DELETEEC
@EC_Id int,
@Case tinyint,
@User_Id int,
@Rows int OUTPUT
as
Declare @ETId Int,@PUId Int
Declare @Insert_Id int
INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEMEC_DELETEEC',
             Convert(nVarChar(10),@EC_Id) + ','  + 
             Convert(nVarChar(10),@Case) + ','  + 
             Convert(nVarChar(10),@User_Id), dbo.fnServer_CmnGetDate(getUTCdate()))
SELECT @Insert_Id = Scope_Identity()
select @Rows = 0
create table #ids(theId int)
Insert Into #Ids
  select ECV_Id from event_configuration_data where ec_id = @EC_Id
if @Case = 0
  Begin
    select @Rows = count(*) from #ids
  End
--DELETE Event Configuration Data and Values!
else if @Case = 1
  Begin
    DELETE from event_configuration_data Where ec_id = @EC_Id
    DELETE from event_configuration_values Where ecv_id in (Select theId from #Ids)
 	 DELETE From Event_Configuration_Properties Where  EC_Id = @EC_Id
  End
--DELETE Event Configuration!
else if @Case = 2
  Begin
    Select @ETId = Et_Id,@PUId = PU_Id From event_configuration Where ec_id = @EC_Id
    /* cannot do waste (can have multiple waste on an unit) */
    If @ETId  = 2
       Execute spEMEC_DTAssociation @PUId,@ETId,0,@User_Id
 	  If @ETId  = 3  --waste
 	  BEGIN
 	   	  If (select Count(*) From event_configuration Where Et_Id = 3 and PU_Id = @PUId) = 1 -- last one
 	  	  	 Begin
 	  	  	  	 Execute spEMEC_DTAssociation @PUId,@ETId,0,@User_Id
 	  	  	  	 --DELETE From Prod_Events where PU_Id = @PUId and Event_Type = 3
 	  	  	  	 --update waste_event_Details set  WEFault_Id = Null,WEMT_Id  = Null Where PU_Id = @PUId and (WEFault_Id is not null or WEMT_Id is not null)
 	  	  	  	 --DELETE From Waste_Event_Meas where PU_Id = @PUId
 	  	  	  	 --DELETE From waste_Event_fault where PU_Id = @PUId
 	  	  	 End
 	  	 UPDATE waste_event_Details set  EC_Id = Null Where EC_Id = @EC_Id
 	 END
    DELETE from event_configuration_data Where ec_id = @EC_Id
    DELETE from event_configuration_values Where ecv_id in (select theId from #Ids)
 	  DELETE From Event_Configuration_Properties Where  EC_Id = @EC_Id
    Declare @Comment_Id int
    Select @Comment_Id = comment_id from Event_Configuration where EC_Id = @EC_Id
    if @Comment_Id is not null
 	 BEGIN
 	  	 DELETE From Comments Where TopOfChain_Id = @Comment_Id 
 	  	 DELETE From Comments Where Comment_Id = @Comment_Id 
 	 END
 	 exec spEMEC_ConfigureModel5014 @EC_Id, 0
    DELETE from event_configuration where ec_id = @EC_Id
  End
drop table #ids
if (select count(*) from event_configuration where ed_model_id = 100) = 0 and (@Case = 1 or @Case = 2)
  begin
 	  	 declare @ECId int, @IsActive tinyint
 	  	 select @ECId = EC_Id, @IsActive = Is_Active from event_configuration where ed_model_id = 49000 and pu_id = 0
 	  	 if @ECId is not NULL and @IsActive = 1
 	  	  	 exec spEMEC_UpdateIsActive @ECId, 0, @User_Id
 	 end
UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
WHERE Audit_Trail_Id = @Insert_Id

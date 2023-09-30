/*
spEMSEC_PutECData 100074,507,21,'PT:\\HISTORIAN (LOCAL)\800SeriesModels.Model803-ProductChange.ProductionAmount',1,Null,1,2674
select * from event_configuration_values where ecv_Id = 2674
*/
CREATE Procedure dbo.spEMSEC_PutECData
@EdFieldId 	 INT,
@ECId 	  	 INT,
@PUId 	  	 INT,
@Value 	  	 nVarChar(4000),
@IsECField 	 Int,
@AliasName 	 nVarChar(100),
@UserId 	  	 INT,
@ECVId 	  	 INT OUTPUT
AS
SELECT @AliasName = upper(@AliasName)
Declare @AuditId INT
DECLARE @Init nVarChar(4000),@Prec Int
INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@UserId,'spEMSEC_PutECData',
             isnull(Convert(nVarChar(10),@EdFieldId),'Null') + ','  + 
             isnull(Convert(nVarChar(10),@ECId),'Null') + ','  + 
             isnull(Convert(nVarChar(10),@PUId),'Null') + ','  + 
             isnull(SubString(@Value,1,200),'Null') + ','  + 
             isnull(Convert(nVarChar(10),@ECVId),'Null') + ','  + 
             isnull(Convert(nVarChar(10),@IsECField),'Null') + ','  + 
             isnull(Convert(nVarChar(10),@AliasName),'Null') + ','  + 
             Convert(nVarChar(10),@UserId), dbo.fnServer_CmnGetDate(getUTCdate()))
SELECT @AuditId = Scope_Identity()
IF @IsECField = 1
BEGIN
 	 IF @ECVId IS NULL
 	 BEGIN
 	  	 IF @EdFieldId IN(188,192,196,195) -- DownTime Faults/States Do Not save if no tree associated
 	  	 BEGIN
 	  	  	 IF (SELECT count(*) From Prod_Events where pu_Id = @PUId and Event_Type = 2) = 0
 	  	  	 RETURN (0)
 	  	 END
 	  	 IF @EdFieldId IN(2826) -- Waste Faults Do Not save if no tree associated
 	  	 BEGIN
 	  	  	 IF (SELECT count(*) From Prod_Events where pu_Id = @PUId and Event_Type = 3) = 0
 	  	  	 RETURN (0)
 	  	 END
 	  	 DELETE FROM event_configuration_values WHERE ECV_ID = (SELECT ECV_ID FROM event_configuration_data WHERE Alias = @AliasName AND PU_ID = @PUId)
 	  	 DELETE FROM event_configuration_data WHERE Alias = @AliasName AND PU_ID = @PUId
 	  	 SELECT  @Init = isnull(@Value,Default_Value),@Prec = isnull(Percision,0) from ED_Fields where ED_Field_Id = @EdFieldId
 	  	 INSERT into event_configuration_values(value) values (@Init) 
 	  	 SELECT @ECVId = IDENT_CURRENT('event_configuration_values')
 	  	 INSERT into event_configuration_data (EC_Id, ED_Field_Id, ECV_Id, PU_Id,Alias,Input_Precision) Values (@ECId,@EdFieldId,@ECVId,@PUId,@AliasName,@Prec)
 	 END
 	 ELSE
 	 BEGIN
 	  	 DECLARE @LocalHist as nVarChar(100)
 	  	 SELECT @LocalHist = 'PT:\\' + Alias + '\' FROM historians WHERE Hist_Id = -1
 	  	 IF CharIndex( @LocalHist,@Value) > 0
 	  	 BEGIN
 	  	  	 SELECT @Value = Replace( @Value,'PT:','')
 	  	  	 SELECT @Value = 'PT:' + dbo.fnEM_ConvertTagToVarId(@Value)
 	  	 END
 	  	 UPDATE Event_Configuration_Values Set Value = @Value Where ECV_Id = @ECVId
 	 END
END
ELSE IF @IsECField = 0
BEGIN
 	 IF @EdFieldId = 1
 	  	 UPDATE event_configuration Set Extended_Info = @Value  WHERE EC_Id = @ECId
 	 ELSE IF @EdFieldId = 2
 	  	 UPDATE event_configuration Set Exclusions = @Value  WHERE EC_Id = @ECId
 	 ELSE IF @EdFieldId = 3
 	  	 UPDATE event_configuration Set ESignature_Level = @Value  WHERE EC_Id = @ECId
 	 ELSE IF @EdFieldId = 4
 	  	 UPDATE event_configuration Set Max_Run_Time = @Value  WHERE EC_Id = @ECId
 	 ELSE IF @EdFieldId = 5
 	  	 UPDATE event_configuration Set External_Time_Zone = @Value  WHERE EC_Id = @ECId
 	 ELSE IF @EdFieldId = 6
 	  	 UPDATE event_configuration Set Model_Group = @Value  WHERE EC_Id = @ECId
 	 ELSE IF @EdFieldId = 7
 	  	 UPDATE event_configuration Set Move_EndTime_Interval = @Value  WHERE EC_Id = @ECId
END
ELSE IF @IsECField = 2
BEGIN
 	 Declare @Config_Prop_Id Int
 	 Select @Config_Prop_Id = EC_Id From Event_Configuration_Properties Where EC_Id = @ECId and ED_Field_Prop_Id = @EdFieldId
 	 If @Config_Prop_Id is null
 	  	 Insert into Event_Configuration_Properties(EC_Id,ED_Field_Prop_Id,Value) Values (@ECId,@EdFieldId,@Value)
 	 Else
 	  	 Update Event_Configuration_Properties Set Value = @Value Where EC_Id = @ECId and ED_Field_Prop_Id = @EdFieldId
END
UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
WHERE Audit_Trail_Id = @AuditId

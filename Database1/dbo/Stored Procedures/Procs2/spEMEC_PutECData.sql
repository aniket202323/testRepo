CREATE PROCEDURE  dbo.spEMEC_PutECData
 	 @EcId 	  	 Int,
 	 @PUId 	  	 Int,
 	 @Alias 	  	  	 nvarchar(50),
 	 @Trigger 	  	 Bit,
 	 @Value 	 nvarchar(255),
 	 @Attribute 	  	 Int,
 	 @SamplingType 	  	 Int,
 	 @TimeOffset 	  	 Int,
 	 @Input_Precision 	 TinyInt,
 	 @User_Id  	  	 int
 AS
Declare @FieldId Int,
@Insert_Id int
INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEMEC_PutECData',
             Convert(nVarChar(10),@EcId) + ','  + 
             Convert(nVarChar(10),@PUId) + ','  + 
             @Alias + ',' +
             Convert(nVarChar(10),@Trigger) + ','  + 
             @Value + ',' +
             Convert(nVarChar(10),@Attribute) + ','  + 
             Convert(nVarChar(10),@SamplingType) + ','  + 
             Convert(nVarChar(10),@TimeOffset) + ','  + 
             Convert(nVarChar(10),@User_Id), dbo.fnServer_CmnGetDate(getUTCdate()))
SELECT @Insert_Id = Scope_Identity()
Select @FieldId = ED_Field_Id  
  From ed_Fields f
  Join ED_Models m on f.ED_Model_Id = m.ED_Model_Id and m.ED_Model_Id = (Select ED_Model_Id from Event_Configuration Where EC_Id = @ECId)
  Where  ED_Field_Type_Id = 10
declare @ECV_Id int
insert into event_configuration_values(value) values (@Value)
select @ECV_Id = IDENT_CURRENT('event_configuration_values')
Insert into event_configuration_data(EC_Id, ED_Field_Id, Alias , PU_Id, ECV_Id, ED_Attribute_Id, ST_Id, IsTrigger, Sampling_Offset, Input_Precision)
 	 Values (@EcId,@FieldId,@Alias,@PUId,@ECV_Id,@Attribute,@SamplingType,@Trigger,@TimeOffset,@Input_Precision)
UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
WHERE Audit_Trail_Id = @Insert_Id

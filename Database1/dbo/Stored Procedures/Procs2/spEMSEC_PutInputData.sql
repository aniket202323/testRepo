CREATE PROCEDURE  dbo.spEMSEC_PutInputData
 	 @EcId 	  	  	  	 Int,
 	 @PUId 	  	  	  	 Int,
 	 @Alias 	  	  	  	 nvarchar(50),
 	 @Trigger 	  	  	 Bit,
 	 @Value 	  	  	  	 nvarchar(255),
 	 @Attribute 	  	  	 Int,
 	 @SamplingType 	  	 Int,
 	 @TimeOffset 	  	  	 Int,
 	 @Input_Precision 	 TinyInt,
 	 @FieldId 	  	  	 INT,
 	 @User_Id  	  	  	 int,
 	 @ECVID 	  	  	  	 Int 	  	 OUTPUT
 AS
Declare @Insert_Id int
INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEMSEC_PutInputData',
             IsNull(Convert(nVarChar(10),@EcId),'Null') + ','  + 
             IsNull(Convert(nVarChar(10),@PUId),'Null') + ','  + 
             IsNull(@Alias,'Null') + ',' +
             IsNull(Convert(nVarChar(10),@Trigger),'Null') + ','  + 
             IsNull(@Value,'Null') + ',' +
             IsNull(Convert(nVarChar(10),@Attribute),'Null') + ','  + 
             IsNull(Convert(nVarChar(10),@SamplingType),'Null') + ','  + 
             IsNull(Convert(nVarChar(10),@TimeOffset),'Null') + ','  + 
             IsNull(Convert(nVarChar(10),@FieldId),'Null') + ','  + 
             IsNull(Convert(nVarChar(10),@User_Id),'Null') + ','  + 
             IsNull(Convert(nVarChar(10),@ECVID),'Null'), dbo.fnServer_CmnGetDate(getUTCdate()))
SELECT @Insert_Id = Scope_Identity()
/*DELETE*/
If @EcId IS NULL AND  @ECVId IS NOT NULL
BEGIN
   	 Delete From event_configuration_data Where ECV_ID = @ECVId
   	 Delete From event_configuration_values Where ECV_ID = @ECVId
 	 UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0 WHERE Audit_Trail_Id = @Insert_Id
 	 RETURN
END
IF @SamplingType In (101,102,103,104,105)
BEGIN
 	 SELECT @Value = 'CurrentEventProperty:' + convert(nVarChar(1), @SamplingType - 100)
 	 SELECT @SamplingType = Null,@Attribute = Null,@FieldId = 2865,@TimeOffset = Null,@Trigger = Null
 	 SELECT @FieldId = 2865
END
If @ECVID Is Null
BEGIN
 	 insert into event_configuration_values(value) values (@Value)
 	 select @ECVID = IDENT_CURRENT('event_configuration_values')
 	 Insert into event_configuration_data(EC_Id, ED_Field_Id, Alias , PU_Id, ECV_Id, ED_Attribute_Id, ST_Id, IsTrigger, Sampling_Offset, Input_Precision)
 	  	 Values (@EcId,@FieldId,@Alias,@PUId,@ECVID,@Attribute,@SamplingType,@Trigger,@TimeOffset,@Input_Precision)
END
ELSE
BEGIN
 	 UPDATE event_configuration_values Set [value] = @Value WHERE ECV_Id = @ECVID
 	 UPDATE event_configuration_data SET ED_Field_Id = @FieldId, 
 	  	  	  	  	  	  	  	  	  	 Alias = @Alias, 
 	  	  	  	  	  	  	  	  	  	 PU_Id = @PUId, 
 	  	  	  	  	  	  	  	  	  	 ED_Attribute_Id = @Attribute, 
 	  	  	  	  	  	  	  	  	  	 ST_Id = @SamplingType, 
 	  	  	  	  	  	  	  	  	  	 IsTrigger = @Trigger,  
 	  	  	  	  	  	  	  	  	  	 Sampling_Offset = @TimeOffset, 
 	  	  	  	  	  	  	  	  	  	 Input_Precision = @Input_Precision 
 	 WHERE ECV_Id = @ECVID and EC_Id = @EcId
END
UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
WHERE Audit_Trail_Id = @Insert_Id

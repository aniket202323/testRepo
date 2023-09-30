-- spEMSEC_GetEventConfigurationData 12,5331,8
-- spEMSEC_GetEventConfigurationData 238,212,2
-- spEMSEC_GetEventConfigurationData 0,95,400
-- spEMSEC_GetEventConfigurationData 522,51010,409
CREATE Procedure dbo.spEMSEC_GetEventConfigurationData
@ECId int,
@ModelNum Int,
@PUId 	 Int
AS
 	  	 DECLARE @CommentId 	 Int,
 	  	  	  	 @ECDesc 	  	 nVarChar(100),
 	  	  	  	 @ModelMode 	 Int,
 	  	  	  	 @ESigLevel 	 Int,
 	  	  	  	 @EDModelId 	 Int,
 	  	  	  	 @EtId 	  	 Int,
 	  	  	  	 @Ext 	  	 nvarchar(255),
 	  	  	  	 @Exc 	  	 nvarchar(255),
 	  	  	  	 @MaxRunTime Int,
 	  	  	  	 @MoveEndTimeInterval Int,
 	  	  	  	 @ModelGroup 	 Int,
 	  	  	  	 @TZ 	  	  	 nVarChar(200),
 	  	  	  	 @IsRegionalCapable 	 Int
/* Add Location Equipment Values */
 	 DECLARE @PU Table (PU_Id Int)
 	 INSERT INTO @PU (PU_Id) 
 	  	 SELECT   pu.PU_Id
 	  	 From  Prod_Units pu 
 	  	 WHERE pu.PU_Id = @PUId or pu.Master_Unit = @PUId
 	 DECLARE @EQ Table(EQ_Id Int,EQ_Desc nvarchar(30),PU_Id INT)
 	 INSERT INTO @EQ (EQ_Id,EQ_Desc,PU_Id) 
 	  	 SELECT  0,'Unavailable', PU_Id
 	  	 From @PU
 	 INSERT INTO @EQ (EQ_Id,EQ_Desc,PU_Id)
 	  	 SELECT  1,'Down', PU_Id
 	  	 From @PU
 	 INSERT INTO @EQ (EQ_Id,EQ_Desc,PU_Id)
 	  	 SELECT  2,'Starved', PU_Id
 	  	 From @PU
 	 INSERT INTO @EQ (EQ_Id,EQ_Desc,PU_Id)
 	  	 SELECT  3,'Blocked', PU_Id
 	  	 From @PU
 	 Declare @CommonFields Table (FieldName nVarChar(100),FieldId Int,FieldValue nvarchar(255),FieldTypeId Int,Prefix VarChar(5),SpLookup Int,StoreId Int)
 	 
 	 Declare @NonGeneralFields Table (FieldId Int)
 	 /* These Fields do no belong on general tab */
 	 INSERT INTO @NonGeneralFields (FieldId) Values (187)
 	 INSERT INTO @NonGeneralFields (FieldId) Values (190)
 	 INSERT INTO @NonGeneralFields (FieldId) Values (192)
 	 INSERT INTO @NonGeneralFields (FieldId) Values (194)
 	 INSERT INTO @NonGeneralFields (FieldId) Values (195)
 	 INSERT INTO @NonGeneralFields (FieldId) Values (196)
 	 INSERT INTO @NonGeneralFields (FieldId) Values (2822) -- Waste Type Mode
 	 INSERT INTO @NonGeneralFields (FieldId) Values (2823)
 	 INSERT INTO @NonGeneralFields (FieldId) Values (2831)
 	 INSERT INTO @NonGeneralFields (FieldId) Values (2836)
 	 INSERT INTO @NonGeneralFields (FieldId) Values (2840)
 	 INSERT INTO @NonGeneralFields (FieldId) Values (2843)
 	 INSERT INTO @NonGeneralFields (FieldId) Values (2865)
 	 SELECT @TZ=value from site_parameters where parm_id=192
 	 IF @TZ = 'UTC'
 	  	 SET @IsRegionalCapable = 1
 	 ELSE
 	  	 SET @IsRegionalCapable = 0
 	 SELECT @EDModelId = ED_Model_Id,@EtId = ET_Id,@Ext = isnull(Extended_Info,''),@Exc = Isnull(Exclusions,''),@MaxRunTime = IsNull(Max_Run_Time,0),@TZ =  Isnull(External_Time_Zone,@TZ),@ModelGroup = Model_Group
 	  	 FROM event_Configuration
 	  	 WHERE ec_Id = @ECId
 	 IF @ECId Is Not NUll and @EDModelId Is Null AND @EtId Is Not Null
 	 BEGIN
 	  	 SELECT  @EDModelId = Case When @EtId = 2  Then  30
 	  	  	  	  	  	  	 When @EtId = 3  Then  5401
 	  	  	  	  	  	  	 When @EtId = 1  Then  5402
 	  	  	  	  	  	  	 When @EtId = 30 Then  5403
 	  	  	  	  	  	  	 When @EtId = 14 Then  5404
 	  	  	  	  	  	  	 When @EtId = 4  Then  5405
 	  	  	  	  	  	  	 When @EtId = 19 Then  5406
 	  	  	  	  	  	  	 When @EtId = 6 Then  5225
 	  	  	  	  	  	  	 When @EtId = 7 Then  5190
 	  	  	  	  	  	  	 When @EtId = 8 Then  5215
 	  	  	  	  	  	  	 When @EtId = 10 Then  5232
 	  	  	  	  	  	  	 When @EtId = 21 Then  5380
 	  	  	  	  	  	  	 When @EtId = 23 Then  5259
 	  	  	  	  	  	  	 When @EtId = 24 Then  5283
 	  	  	  	  	  	  	 When @EtId = 25 Then  5278
 	  	  	  	  	  	  	 ELSE Null
 	  	  	  	  	  	 End
 	  	 UPDATE Event_Configuration Set ed_Model_Id = @EDModelId WHERE ec_Id = @ECId
 	 END
 	 IF @EDModelId Is Null --no model set a default
 	  	 Select @ECId = 0
 	 IF @ECId = 0
 	 BEGIN
 	  	 SELECT @EDModelId = ED_Model_Id,@EtId = ET_Id FROM Ed_Models where Model_Num  = @ModelNum
 	  	 SELECT CommentId = 0 ,ECDesc =isnull(Model_Desc,'')
 	  	  	 FROM Ed_Models 
 	  	  	 WHERE ED_Model_Id = @EDModelId 
 	  	 Select @Ext = isnull(@Ext,''),@Exc = Isnull(@Exc,''),@MaxRunTime = IsNull(@MaxRunTime,0),@MoveEndTimeInterval = IsNull(@MoveEndTimeInterval,0)
 	  	 INSERT INTO @CommonFields (FieldName,FieldValue,FieldId,FieldTypeId,Prefix,SpLookup,StoreId) VALUES ('Maximum Run Time (Seconds) 0 = No Limit',@MaxRunTime,4,2,'',0,0)
 	  	 INSERT INTO @CommonFields (FieldName,FieldValue,FieldId,FieldTypeId,Prefix,SpLookup,StoreId) VALUES ('Extended Information',@Ext,1,1,'',0,0)
 	  	 INSERT INTO @CommonFields (FieldName,FieldValue,FieldId,FieldTypeId,Prefix,SpLookup,StoreId) VALUES ('Exclusions(e.g. 12,34,32)',@Exc,2,1,'',0,0)
 	  	 INSERT INTO @CommonFields (FieldName,FieldValue,FieldId,FieldTypeId,Prefix,SpLookup,StoreId) VALUES ('Model Processing Group',@ModelGroup,6,2,'',0,0)
 	  	 IF @EtId in (1)
 	  	  	 INSERT INTO @CommonFields (FieldName,FieldValue,FieldId,FieldTypeId,Prefix,SpLookup,StoreId) VALUES ('Auto Move End Time (Minutes) 0 = Off',@MoveEndTimeInterval,7,2,'',0,0)
 	  	 IF  @ModelNum in (200,210,211,212,304)
 	  	  	 INSERT INTO @CommonFields (FieldName,FieldValue,FieldId,FieldTypeId,Prefix,SpLookup,StoreId) VALUES ('Esignature level',@ESigLevel,3,55,'',1,1)
 	  	 IF  @IsRegionalCapable = 1 and @ModelNum in (29,30,31,40,50,53,60,63,70,71,72,73,74,78,85,86,87,93,94,95,5013,106,604,605,607)
 	  	  	 INSERT INTO @CommonFields (FieldName,FieldValue,FieldId,FieldTypeId,Prefix,SpLookup,StoreId) VALUES ('Time Zone',@TZ,5,67,'',0,0)
 	  	 SELECT FieldName,FieldValue,FieldId,FieldTypeId,Prefix,SpLookup,StoreId,Max_Instances = 1 FROM  @CommonFields order by FieldName
 	  	 SELECT ef.Field_Desc,ef.ED_Field_Type_Id,Prefix,SP_Lookup,Store_Id,ECV_ID = NULL,ef.Ed_Field_Id,[Value] =  Convert(varchar(7000),Default_Value) ,
 	  	  	 ValueText = Null,Max_Instances,
 	  	  	 Table_Id = 1,ef.field_order,Locked = isNull(ef.Locked,0)
 	  	  	  FROM Ed_Models em
 	  	  	 JOIN Ed_Fields ef ON ef.ED_Model_Id = em.ED_Model_Id and ED_Field_Type_Id Not In ( 17,18,20,65) and ed_Field_Id  Not IN (Select FieldId From @NonGeneralFields )
 	  	  	 JOIN ed_Fieldtypes edf on edf.ED_Field_Type_Id = ef.ED_Field_Type_Id
 	  	     WHERE em.ED_Model_Id = @EDModelId 
UNION
 	 SELECT fp.Field_Desc,fp.ED_Field_Type_Id,Prefix,SP_Lookup,Store_Id,
 	  	  	 ECV_ID = Null,Ed_Field_Id = fp.ED_Field_Prop_Id,
 	  	  	 [Value] = convert(varchar(7000),fp.Default_Value),
 	  	  	 ValueText = Null,Max_Instances =1,
 	  	  	 Table_Id = 2,field_order = 999,Locked = IsNull(fp.locked,0)
 	  	 FROM  Ed_Models em 
 	  	 Join ED_Field_Properties fp on fp.ED_Model_Id = em.ED_Model_Id
 	  	 JOIN ed_Fieldtypes edf on edf.ED_Field_Type_Id = fp.ED_Field_Type_Id
 	 WHERE em.ED_Model_Id = @EDModelId 
 order by Table_Id , field_order,Field_Desc
 	  	 SELECT ECV_ID = Null,ef.Ed_Field_Id,[Value] = es.VB_Script ,TabNumber
 	  	 From  Ed_Models em 
 	  	 JOIN Ed_Fields ef ON ef.ED_Model_Id = em.ED_Model_Id and ED_Field_Type_Id  In ( 17,18,65)
 	  	 Left Join ed_Script es on es.ED_Model_Id = em.ED_Model_Id and ef.Ed_Field_Id = es.ED_Field_Id
 	  	 WHERE em.ED_Model_Id = @EDModelId order by TabNumber
 	  	 SELECT Distinct  pu.PU_Id,ECV_ID = Null,ef.Ed_Field_Id,[Value] = es.VB_Script  ,TabNumber
 	  	  	 From Ed_Models em 
 	  	  	 JOIN Ed_Fields ef ON ef.ED_Model_Id = em.ED_Model_Id and ED_Field_Type_Id  = 20
 	  	  	 Join Prod_Units pu ON pu.PU_Id = @PUId or pu.Master_Unit = @PUId
 	  	  	 Left Join ed_Script es on es.ED_Model_Id = em.ED_Model_Id and ef.Ed_Field_Id = es.ED_Field_Id and script_Desc = '<User Defined>'
 	  	 WHERE em.ED_Model_Id = @EDModelId order by TabNumber
 	  	 /* Location Scripts */
 	  	 SELECT   EQ_Id,Alias = EQ_Desc ,pu.PU_Id,ECV_ID = Null,ef.Ed_Field_Id,[Value] = es.VB_Script,TabNumber = 4
 	  	  	  	 FROM  Ed_Models em 
 	  	  	  	 JOIN Ed_Fields ef ON ef.ED_Model_Id = em.ED_Model_Id and ED_Field_Type_Id  = 19
 	  	  	  	 Join Prod_Units pu ON pu.PU_Id = @PUId or pu.Master_Unit = @PUId
 	  	  	  	 Left Join @EQ eq on eq.PU_Id = pu.PU_Id and @ModelNum = 212
 	  	  	  	 Left Join ed_Script es on es.ED_Model_Id = em.ED_Model_Id and ef.Ed_Field_Id = es.ED_Field_Id and script_Desc = '<User Defined>'
 	  	  	 WHERE em.ED_Model_Id = @EDModelId order by TabNumber
 	 END
ELSE
BEGIN
 	 /* FILL GENERAL TAB ONLY */
 	 SELECT @CommentId = Isnull(Comment_Id,0),
 	  	  	 @ECDesc = Isnull(EC_Desc,''),
 	  	  	 @ESigLevel = isnull(ESignature_Level,0),
 	  	  	 @EDModelId = isnull(ED_Model_Id,-1),
 	  	  	 @Ext = isnull(Extended_Info,''),
 	  	  	 @Exc = isnull(Exclusions,''),
 	  	  	 @ModelGroup = Model_Group,
 	  	  	 @MaxRunTime = IsNull(Max_Run_Time,0),
 	  	  	 @TZ = Isnull(External_Time_Zone,@TZ),
 	  	  	 @MoveEndTimeInterval = IsNull(Move_EndTime_Interval,0)
 	  	 FROM event_Configuration where ec_Id = @ECId
 	 INSERT INTO @CommonFields (FieldName,FieldValue,FieldId,FieldTypeId,Prefix,SpLookup,StoreId) VALUES ('Maximum Run Time (Seconds) 0 = No Limit',@MaxRunTime,4,2,'',0,0)
 	 INSERT INTO @CommonFields (FieldName,FieldValue,FieldId,FieldTypeId,Prefix,SpLookup,StoreId) VALUES ('Extended Information',@Ext,1,1,'',0,0)
 	 INSERT INTO @CommonFields (FieldName,FieldValue,FieldId,FieldTypeId,Prefix,SpLookup,StoreId) VALUES ('Exclusions(e.g. 12,34,32)',@Exc,2,1,'',0,0)
 	 INSERT INTO @CommonFields (FieldName,FieldValue,FieldId,FieldTypeId,Prefix,SpLookup,StoreId) VALUES ('Model Processing Group',@ModelGroup,6,2,'',0,0)
 	 IF @EtId in (1)
 	  	 INSERT INTO @CommonFields (FieldName,FieldValue,FieldId,FieldTypeId,Prefix,SpLookup,StoreId) VALUES ('Auto Move End Time (Minutes) 0 = Off',@MoveEndTimeInterval,7,2,'',0,0)
 	 IF  @ModelNum in (200,210,211,212,304)
 	  	 INSERT INTO @CommonFields (FieldName,FieldValue,FieldId,FieldTypeId,Prefix,SpLookup,StoreId) VALUES ('Esignature level',@ESigLevel,3,55,'',1,1)
 	 IF  @IsRegionalCapable = 1 and @ModelNum in (29,30,31,40,50,53,60,63,70,71,72,73,74,78,85,86,87,93,94,95,5013,106,604,605,607)
 	  	 INSERT INTO @CommonFields (FieldName,FieldValue,FieldId,FieldTypeId,Prefix,SpLookup,StoreId) VALUES ('Time Zone',@TZ,5,67,'',0,0)
 	 SELECT CommentId =isnull(@CommentId,0) ,ECDesc =isnull(@ECDesc,'')
 	 SELECT FieldName,FieldValue,FieldId,FieldTypeId,Prefix,SpLookup,StoreId,Max_Instances = 1 FROM  @CommonFields order by FieldName
 	 DECLARE @LocalHist as nVarChar(100)
 	 SELECT @LocalHist = 'PT:\\' + Alias + '\' FROM historians WHERE Hist_Id = -1
 	 SELECT ef.Field_Desc,ef.ED_Field_Type_Id,Prefix,SP_Lookup,Store_Id,
 	  	  	 ef.ED_Field_Id,ecd.ECV_ID,ef.Ed_Field_Id,
 	  	  	 Value = CASE
 	  	  	  	  	  	 WHEN  ecv.Value Is Not NULL  AND  CharIndex( @LocalHist,ecv.Value) > 0 THEN 'PT:' + dbo.fnEM_ConvertVarIdToTag(REPLACE(Convert(varchar(7000),ecv.Value),'PT:','')) 	 
 	  	  	  	  	  	 WHEN ef.Default_Value is Not Null  and CharIndex( @LocalHist,ef.Default_Value) > 0   THEN 'PT:' + dbo.fnEM_ConvertVarIdToTag(REPLACE(Convert(varchar(7000),ef.Default_Value),'PT:',''))
 	  	  	  	  	  	 ELSE Isnull(convert(VARCHAR(7000),ecv.Value),ef.Default_Value)
 	  	  	  	  	 END,
 	  	  	 Max_Instances,
 	  	  	 ValueText = Case  ef.ED_Field_Type_Id When 9 then
 	  	  	  	  	  	  	 (SELECT PU_Desc From Prod_Units where PU_Id = convert(nVarChar(10),ecv.Value))
 	  	  	  	  	  	 When 10 then
 	  	  	  	  	  	  	 (SELECT PL_Desc + '\' + PU_Desc + '\' + Var_Desc 
 	  	  	  	  	  	  	  	 From Variables v
 	  	  	  	  	  	  	  	 Join Prod_Units pu On pu.PU_Id = v.PU_id
 	  	  	  	  	  	  	  	 Join Prod_lines pl on pl.PL_Id = pu.PL_Id where Var_Id = convert(nVarChar(10),ecv.Value))
 	  	  	  	  	  	 ELSE ''
 	  	  	  	  	  	 End,
 	  	  	 Table_Id = 1,ef.field_order,Locked = IsNull(ef.locked,0)
 	  	 From event_Configuration ec
 	     Join  Ed_Models em ON em.ED_Model_Id = ec.ED_Model_Id
 	  	 JOIN Ed_Fields ef ON ef.ED_Model_Id = em.ED_Model_Id and ED_Field_Type_Id Not In ( 17,18,20,65) and ef.ed_Field_Id  Not IN (Select FieldId From @NonGeneralFields )
 	  	 Left Join Event_Configuration_Data ecd on ec.EC_ID = ecd.EC_ID and ecd.ED_Field_Id = ef.ED_Field_Id
 	  	 LEFT JOIN event_configuration_values ecv On ecd.ECV_Id = ecv.Ecv_Id
 	  	 Left JOIN ed_Fieldtypes edf on edf.ED_Field_Type_Id = ef.ED_Field_Type_Id
 	 WHERE ec.ec_Id = @ECId
UNION
 	 SELECT fp.Field_Desc,fp.ED_Field_Type_Id,Prefix,SP_Lookup,Store_Id,
 	  	  	 ED_Field_Id = fp.ED_Field_Prop_Id,ECV_ID = case when  ecp.Value is Null then Null else -1 end,Ed_Field_Id = fp.ED_Field_Prop_Id,
 	  	  	 Value = Isnull(ecp.Value,fp.Default_Value),Max_Instances =1,
 	  	  	 ValueText = Case  fp.ED_Field_Type_Id When 9 then
 	  	  	  	  	  	  	 (SELECT PU_Desc From Prod_Units where PU_Id = convert(nVarChar(10),ecp.Value))
 	  	  	  	  	  	 When 10 then
 	  	  	  	  	  	  	 (SELECT PL_Desc + '\' + PU_Desc + '\' + Var_Desc 
 	  	  	  	  	  	  	  	 From Variables v
 	  	  	  	  	  	  	  	 Join Prod_Units pu On pu.PU_Id = v.PU_id
 	  	  	  	  	  	  	  	 Join Prod_lines pl on pl.PL_Id = pu.PL_Id where Var_Id = convert(nVarChar(10),ecp.Value))
 	  	  	  	  	  	 ELSE ''
 	  	  	  	  	  	 End,
 	  	  	 Table_Id = 2,field_order = 999,Locked = IsNull(fp.locked,0)
 	  	 From event_Configuration ec
 	     Join  Ed_Models em ON em.ED_Model_Id = ec.ED_Model_Id
 	  	 Join ED_Field_Properties fp on fp.ED_Model_Id = em.ED_Model_Id
 	  	 Left Join event_configuration_Properties ecp on ec.EC_ID = ecp.EC_ID and ecp.ED_Field_Prop_Id = fp.ED_Field_Prop_Id
 	  	 Left JOIN ed_Fieldtypes edf on edf.ED_Field_Type_Id = fp.ED_Field_Type_Id
 	 WHERE ec.ec_Id = @ECId
 order by Table_Id , field_order,Field_Desc
/* Single Scripts */
 	 SELECT Distinct  ecd.ECV_ID,ef.Ed_Field_Id,[Value] = isnull(convert(varchar(7000),ecv.Value),''),TabNumber
 	  	 From event_Configuration ec
 	  	 Join  Ed_Models em ON em.ED_Model_Id = ec.ED_Model_Id
 	  	 JOIN Ed_Fields ef ON ef.ED_Model_Id = em.ED_Model_Id and ED_Field_Type_Id  In ( 17,18,65)
 	  	 Left Join Event_Configuration_Data ecd on ec.EC_ID = ecd.EC_ID and ecd.ED_Field_Id = ef.ED_Field_Id
 	  	 LEFT JOIN event_configuration_values ecv On ecd.ECV_Id = ecv.Ecv_Id
 	  	 Left Join ed_Script es on es.ED_Model_Id = ec.ED_Model_Id and ef.Ed_Field_Id = es.ED_Field_Id
 	 WHERE ec.ec_Id = @ECId order by TabNumber
/* Fault Scripts */
 	 SELECT Distinct  pu.PU_Id,ecd.ECV_ID,ef.Ed_Field_Id,[Value] = isnull(convert(varchar(7000),ecv.Value),''),TabNumber
 	  	 From event_Configuration ec
 	  	 Join  Ed_Models em ON em.ED_Model_Id = ec.ED_Model_Id
 	  	 JOIN Ed_Fields ef ON ef.ED_Model_Id = em.ED_Model_Id and ED_Field_Type_Id  = 20
 	  	 Join Prod_Units pu ON pu.PU_Id = ec.PU_Id or pu.Master_Unit = ec.PU_Id
 	  	 Left Join Event_Configuration_Data ecd on ec.EC_ID = ecd.EC_ID and ecd.ED_Field_Id = ef.ED_Field_Id and ecd.PU_Id = pu.PU_Id
 	  	 LEFT JOIN event_configuration_values ecv On ecd.ECV_Id = ecv.Ecv_Id
 	  	 Left Join ed_Script es on es.ED_Model_Id = ec.ED_Model_Id and ef.Ed_Field_Id = es.ED_Field_Id
 	 WHERE ec.ec_Id = @ECId order by TabNumber
/* Location Scripts */
SELECT   EQ_Id,Alias = isnull(Alias,EQ_Desc) ,pu.PU_Id,ecd.ECV_ID,ef.Ed_Field_Id,[Value] = isnull(convert(varchar(7000),ecv.Value),''),TabNumber = 4
 	  	 From event_Configuration ec
 	  	 Join  Ed_Models em ON em.ED_Model_Id = ec.ED_Model_Id
 	  	 JOIN Ed_Fields ef ON ef.ED_Model_Id = em.ED_Model_Id and ED_Field_Type_Id  = 19
 	  	 Join Prod_Units pu ON pu.PU_Id = ec.PU_Id or pu.Master_Unit = ec.PU_Id
 	  	 Left Join @EQ eq on eq.PU_Id = pu.PU_Id and @ModelNum = 212
 	  	 Left Join Event_Configuration_Data ecd on ec.EC_ID = ecd.EC_ID and ecd.ED_Field_Id = ef.ED_Field_Id and ecd.PU_Id = eq.PU_Id and eq.EQ_Desc = ecd.Alias
 	  	 LEFT JOIN event_configuration_values ecv On ecd.ECV_Id = ecv.Ecv_Id
 	 WHERE ec.ec_Id = @ECId
END
IF  @ModelNum in (200,201,210,211,212) or  @EtId = 2 --DOWNIME SCRIPTABLE
BEGIN
 	 SELECT @ModelMode = Case  @ModelNum WHEN 210 then 1
 	  	  	  	  	  	  	  	  	  	  	  	 WHEN 211 then 2
 	  	  	  	  	  	  	  	  	  	  	  	 WHEN 212 then 3
 	  	  	  	  	  	  	  	  	  	  	  	 ELSE 4
 	  	  	  	  	  	  	  	  	  	  	  	 END
/* Inputs*/
 	  	  	 SELECT d.ecv_id,f.ed_field_id,Alias , d.PU_Id, value = substring(convert(nvarchar(255),Value),4,LEN(convert(nvarchar(255),Value))),Attribute_Desc, ST_Desc, IsTrigger = isnull(IsTrigger,0), Sampling_Offset, Input_Precision
 	  	  	  	 FROM ed_fields f 
 	  	  	  	 JOIN ed_fieldtypes t on f.ed_field_type_id = t.ed_field_type_id 
 	  	  	  	 JOIN event_configuration c on  ec_id = @EcId
 	  	  	  	 JOIN event_configuration_data d on d.ec_id = c.ec_id and d.ed_field_id = f.ed_field_id 
 	  	  	  	 JOIN event_configuration_values v on v.ecv_id = d.ecv_id
 	  	  	  	 JOIN ed_attributes a On d.ED_Attribute_Id = a.ED_Attribute_Id
 	  	  	  	 JOIN sampling_type s on s.ST_Id = d.St_Id
 	  	  	  	 Where c.EC_Id = @EcId and d.PU_Id = @PUId And f.ed_field_type_id = 3 	 --Tag
 	  	  	  	 Order by len(Alias),Alias
 	  	 SELECT ModelMode = @ModelMode
 	  	 /* Load Location Tab*/
 	  	 SELECT  pu.pu_order, 
 	  	  	  	 pu.pu_desc,
 	  	  	  	 ActionTree =  isnull(ert1.tree_name ,'<Unassigned>'),
 	  	  	  	 ActionTreeId =  pe.Action_Tree_Id,
 	  	  	  	 ActionTreeEnabled =  isnull(pe.Action_Reason_Enabled ,0),
 	  	  	  	 pu.pu_id, 
 	  	  	  	 Reason_Tree =  isnull(ert.tree_name ,'<Unassigned>'),
 	  	  	  	 Reason_Tree_Id = isNull(pe.name_id,0),
 	  	  	  	 timed_event_association = isnull(timed_event_association,0),
 	  	  	  	 pu.Master_Unit,
 	  	  	  	 ResearchEnabled = isnull(convert(int,pe.Research_Enabled),0)
 	  	  	 FROM Prod_Units pu
 	  	  	 LEFT JOIN prod_events pe on pe.pu_id = pu.pu_id and pe.event_type = 2
 	  	  	 LEFT JOIN event_reason_tree ert on ert.tree_name_id = pe.name_Id
 	  	  	 LEFT JOIN event_reason_tree ert1 on ert1.tree_name_id = pe.Action_Tree_Id
 	  	  	 where (pu.master_unit = @PUId or pu.pu_id = @PUId)
 	  	  	 order by pu.pu_order
 	  	 /* Load Fault Tab*/
 	  	 SELECT  t.TEFault_Id,t.TEFault_Name,t.Source_PU_Id,
                 Reason_Level1 = isnull(er1.Event_Reason_Name,''),
                 Reason_Level2 = isnull(er2.Event_Reason_Name,''),
                 Reason_Level3 = isnull(er3.Event_Reason_Name,''),
                 Reason_Level4 = isnull(er4.Event_Reason_Name,''),
                 t.TEFault_Value
 	  	  	  	 FROM Timed_Event_Fault t
 	  	  	  	 Left Join Prod_Units pu On pu.PU_Id = t.Source_PU_Id
 	  	  	  	 Left Join Prod_Events pe on pe.PU_Id = pu.PU_Id and  pe.Event_Type = 2
 	  	  	  	 LEFT JOIN Event_Reasons er1 ON t.Reason_Level1 = er1.Event_Reason_Id 
 	  	  	  	 LEFT JOIN Event_Reasons er2 ON t.Reason_Level2 = er2.Event_Reason_Id 
 	  	  	  	 LEFT JOIN Event_Reasons er3 ON t.Reason_Level3 = er3.Event_Reason_Id 
 	  	  	  	 LEFT JOIN Event_Reasons er4 ON t.Reason_Level4 = er4.Event_Reason_Id 
 	  	  	  	 WHERE   t.PU_Id  = @PUId
 	  	  	  	 ORDER BY TEFault_Name
 	  	  	 /* Reason shortcuts */
 	  	  	 SELECT  RS_Id,ShortCut_Name,Source_PU_Id,
 	  	  	  	  	 Reason_Level1 = isnull(er1.Event_Reason_Name,''),
 	  	  	  	  	  Reason_Level2 = isnull(er2.Event_Reason_Name,''),
 	  	  	  	  	  Reason_Level3 = isnull(er3.Event_Reason_Name,''),
 	  	  	  	  	  Reason_Level4 = isnull(er4.Event_Reason_Name,''),
 	  	  	  	  	  Amount =isnull(convert(nVarChar(25),Amount),'')
 	  	  	 FROM Reason_Shortcuts r
 	  	  	 LEFT JOIN Event_Reasons er1 ON r.Reason_Level1 = er1.Event_Reason_Id 
 	  	  	 LEFT JOIN Event_Reasons er2 ON r.Reason_Level2 = er2.Event_Reason_Id 
 	  	  	 LEFT JOIN Event_Reasons er3 ON r.Reason_Level3 = er3.Event_Reason_Id 
 	  	  	 LEFT JOIN Event_Reasons er4 ON r.Reason_Level4 = er4.Event_Reason_Id 
 	  	  	 WHERE   PU_Id  = @PUId  AND  App_Id = 2
/* Timed Event Status */
 	  	   SELECT  TEStatus_Id, TEStatus_Name, TEStatus_Value
 	  	  	 FROM Timed_Event_Status
 	  	  	 WHERE   PU_Id  = @PUId
 	  	  	 ORDER BY TEStatus_Name, TEStatus_Value
/* Mode */
 	  	  	 SELECT d.ecv_id,Mode = convert(Int,ISNULL(Convert(nVarChar(10),Value),0))
 	  	  	  	 From  event_configuration c
 	  	  	  	 JOIN event_configuration_data d on d.ec_id = c.ec_id 
 	  	  	  	 Join ed_fields f  On f.ed_field_id = d.ed_field_id And f.ed_field_type_id = 62
 	  	  	  	 Left JOIN event_configuration_values v on v.ecv_id = d.ecv_id
 	  	  	  	 Where c.EC_Id = @EcId
END
ELSE IF  @ModelNum = 801 --Crew Shift Script
BEGIN
 	  	  	 SELECT d.ecv_id,f.ed_field_id,Alias , d.PU_Id, value = substring(convert(nvarchar(255),Value),4,LEN(convert(nvarchar(255),Value))),Attribute_Desc, ST_Desc, IsTrigger = isnull(IsTrigger,0), Sampling_Offset, Input_Precision
 	  	  	  	 FROM ed_fields f 
 	  	  	  	 JOIN ed_fieldtypes t on f.ed_field_type_id = t.ed_field_type_id 
 	  	  	  	 JOIN event_configuration c on  ec_id = @EcId
 	  	  	  	 JOIN event_configuration_data d on d.ec_id = c.ec_id and d.ed_field_id = f.ed_field_id 
 	  	  	  	 JOIN event_configuration_values v on v.ecv_id = d.ecv_id
 	  	  	  	 JOIN ed_attributes a On d.ED_Attribute_Id = a.ED_Attribute_Id
 	  	  	  	 JOIN sampling_type s on s.ST_Id = d.St_Id
 	  	  	  	 Where c.EC_Id = @EcId and d.PU_Id = @PUId And f.ed_field_type_id = 3 	 --Tag
 	  	  	  	 Order by len(Alias),Alias
END
ELSE IF  @EtId = 3 -- Waste 
BEGIN
/* Inputs*/
 	 If @ModelNum = 304 --only inputs for 304
 	 BEGIN
 	  	  	 SELECT d.ecv_id,f.ed_field_id,Alias , d.PU_Id, value = substring(convert(nvarchar(255),Value),4,LEN(convert(nvarchar(255),Value))),Attribute_Desc, ST_Desc, IsTrigger = isnull(IsTrigger,0), Sampling_Offset, Input_Precision
 	  	  	  	 FROM ed_fields f 
 	  	  	  	 JOIN ed_fieldtypes t on f.ed_field_type_id = t.ed_field_type_id 
 	  	  	  	 JOIN event_configuration c on  ec_id = @EcId
 	  	  	  	 JOIN event_configuration_data d on d.ec_id = c.ec_id and d.ed_field_id = f.ed_field_id 
 	  	  	  	 JOIN event_configuration_values v on v.ecv_id = d.ecv_id
 	  	  	  	 JOIN ed_attributes a On d.ED_Attribute_Id = a.ED_Attribute_Id
 	  	  	  	 JOIN sampling_type s on s.ST_Id = d.St_Id
 	  	  	  	 Where c.EC_Id = @EcId and d.PU_Id = @PUId And f.ed_field_type_id = 3 	 --Tag
 	  	  	  	 Order by len(Alias),Alias
 	  	  	 /*Model Type*/
 	  	  	 SELECT ModelMode = convert(int,Convert(nVarChar(10),Value)),ecv.ECV_Id
 	  	  	  From event_Configuration_Data ecd
 	  	  	  Join event_Configuration_Values ecv on ecv.ECV_Id = ecd.ECV_Id
 	  	  	  Where Ec_Id = @ECId and ED_Field_Id  =  2822
 	 END
 	 ELSE
 	 BEGIN
 	  	 Select Empty_Result_Set = 1
 	  	  	 Where 1=2
 	  	 Select Empty_Result_Set = 1
 	  	  	 Where 1=2
 	 END
 	  	 /* Load Location Tab*/
 	  	 SELECT  pu.pu_order, 
 	  	  	  	 pu.pu_desc,
 	  	  	  	 ActionTree =  isnull(ert1.tree_name ,'<Unassigned>'),
 	  	  	  	 ActionTreeId =  pe.Action_Tree_Id,
 	  	  	  	 ActionTreeEnabled =  isnull(pe.Action_Reason_Enabled ,0),
 	  	  	  	 pu.pu_id, 
 	  	  	  	 Reason_Tree =  isnull(ert.tree_name ,'<Unassigned>'),
 	  	  	  	 Reason_Tree_Id = isNull(pe.name_id,0),
 	  	  	  	 Waste_Event_Association = isnull(Waste_Event_Association,0),
 	  	  	  	 pu.Master_Unit,
 	  	  	  	 ResearchEnabled = isnull(convert(int,pe.Research_Enabled),0)
 	  	  	 FROM Prod_Units pu
 	  	  	 LEFT JOIN prod_events pe on pe.pu_id = pu.pu_id and pe.event_type = 3
 	  	  	 LEFT JOIN event_reason_tree ert on ert.tree_name_id = pe.name_Id
 	  	  	 LEFT JOIN event_reason_tree ert1 on ert1.tree_name_id = pe.Action_Tree_Id
 	  	  	 where (pu.master_unit = @PUId or pu.pu_id = @PUId)
 	  	  	 order by pu.pu_order
 	  	 /* Load Fault Tab*/
 	  	 SELECT  t.WEFault_Id,t.WEFault_Name,t.Source_PU_Id,
                 Reason_Level1 = isnull(er1.Event_Reason_Name,''),
                 Reason_Level2 = isnull(er2.Event_Reason_Name,''),
                 Reason_Level3 = isnull(er3.Event_Reason_Name,''),
                 Reason_Level4 = isnull(er4.Event_Reason_Name,''),
                 t.WEFault_Value
 	  	  	  	 FROM Waste_Event_Fault t
 	  	  	  	 Left Join Prod_Units pu On pu.PU_Id = t.Source_PU_Id
 	  	  	  	 LEFT JOIN Event_Reasons er1 ON t.Reason_Level1 = er1.Event_Reason_Id 
 	  	  	  	 LEFT JOIN Event_Reasons er2 ON t.Reason_Level2 = er2.Event_Reason_Id 
 	  	  	  	 LEFT JOIN Event_Reasons er3 ON t.Reason_Level3 = er3.Event_Reason_Id 
 	  	  	  	 LEFT JOIN Event_Reasons er4 ON t.Reason_Level4 = er4.Event_Reason_Id 
 	  	  	  	 WHERE   t.PU_Id  = @PUId
 	  	  	  	 ORDER BY WEFault_Name
 	  	  	 /* Reason shortcuts */
 	  	  	 SELECT  RS_Id,ShortCut_Name,Source_PU_Id,
 	  	  	  	  	 Reason_Level1 = isnull(er1.Event_Reason_Name,''),
 	  	  	  	  	  Reason_Level2 = isnull(er2.Event_Reason_Name,''),
 	  	  	  	  	  Reason_Level3 = isnull(er3.Event_Reason_Name,''),
 	  	  	  	  	  Reason_Level4 = isnull(er4.Event_Reason_Name,''),
 	  	  	  	  	  Amount =isnull(convert(nVarChar(25),Amount),'')
 	  	  	 FROM Reason_Shortcuts r
 	  	  	 LEFT JOIN Event_Reasons er1 ON r.Reason_Level1 = er1.Event_Reason_Id 
 	  	  	 LEFT JOIN Event_Reasons er2 ON r.Reason_Level2 = er2.Event_Reason_Id 
 	  	  	 LEFT JOIN Event_Reasons er3 ON r.Reason_Level3 = er3.Event_Reason_Id 
 	  	  	 LEFT JOIN Event_Reasons er4 ON r.Reason_Level4 = er4.Event_Reason_Id 
 	  	  	 WHERE   PU_Id  = @PUId  AND  App_Id = 3
 	 SELECT  WET_Id,WET_Name,[ReadOnly]
 	  	 FROM Waste_Event_Type
 	 SELECT  WEMT_Id,WEMT_Name,Conversion,Conversion_Spec,VarDesc = PL_Desc + '\' + PU_Desc + '\' + Var_Desc
 	  	 FROM Waste_Event_Meas w
 	  	 LEFT JOIN Variables v ON Conversion_Spec = Var_Id
 	  	 LEFT JOIN Prod_Units pu On pu.PU_Id = v.PU_id
 	  	 LEFT JOIN Prod_lines pl on pl.PL_Id = pu.PL_Id
 	  	 WHERE w.PU_Id  = @PUId
END
ELSE IF  @ModelNum = 800 -- Production Event
BEGIN
 	  	  	 SELECT d.ecv_id,f.ed_field_id,Alias , d.PU_Id, value = substring(convert(nvarchar(255),Value),4,LEN(convert(nvarchar(255),Value))),Attribute_Desc, ST_Desc, IsTrigger = isnull(IsTrigger,0), Sampling_Offset, Input_Precision
 	  	  	  	 FROM ed_fields f 
 	  	  	  	 JOIN ed_fieldtypes t on f.ed_field_type_id = t.ed_field_type_id 
 	  	  	  	 JOIN event_configuration c on  ec_id = @EcId
 	  	  	  	 JOIN event_configuration_data d on d.ec_id = c.ec_id and d.ed_field_id = f.ed_field_id 
 	  	  	  	 JOIN event_configuration_values v on v.ecv_id = d.ecv_id
 	  	  	  	 JOIN ed_attributes a On d.ED_Attribute_Id = a.ED_Attribute_Id
 	  	  	  	 JOIN sampling_type s on s.ST_Id = d.St_Id
 	  	  	  	 Where c.EC_Id = @EcId and d.PU_Id = @PUId And f.ed_field_type_id = 3 	 --Tag
-- 	  	  	  	 Order by len(Alias),Alias
 	  	  	 UNION
 	  	  	 SELECT d.ecv_id,f.ed_field_id,Alias , d.PU_Id, value = '',
 	  	  	  	  	  	 Attribute_Desc = 'Current Event', 
 	  	  	  	  	  	 ST_Desc = a.Field_Desc,
 	  	  	  	  	  	 IsTrigger = 0, 
 	  	  	  	  	  	 Sampling_Offset = 0, 
 	  	  	  	  	  	 Input_Precision = 0
 	  	  	  	 FROM ed_fields f 
 	  	  	  	 JOIN ed_fieldtypes t on f.ed_field_type_id = t.ed_field_type_id 
 	  	  	  	 JOIN event_configuration c on  ec_id = @EcId
 	  	  	  	 JOIN event_configuration_data d on d.ec_id = c.ec_id and d.ed_field_id = f.ed_field_id 
 	  	  	  	 JOIN event_configuration_values v on v.ecv_id = d.ecv_id
 	  	  	  	 JOIN ED_FieldType_ValidValues a on a.Field_Id = right(Substring(v.Value,1,255),1) and a.ED_Field_Type_Id = f.ED_Field_Type_Id
 	  	  	  	 Where c.EC_Id = @EcId and d.PU_Id = @PUId And f.ed_field_type_id = 66 	 --Tag 	  	  	 
END
ELSE IF  @ModelNum = 802 --UDE 
BEGIN
 	  	  	 SELECT d.ecv_id,f.ed_field_id,Alias , d.PU_Id, value = substring(convert(nvarchar(255),Value),4,LEN(convert(nvarchar(255),Value))),Attribute_Desc, ST_Desc, IsTrigger = isnull(IsTrigger,0), Sampling_Offset, Input_Precision
 	  	  	  	 FROM ed_fields f 
 	  	  	  	 JOIN ed_fieldtypes t on f.ed_field_type_id = t.ed_field_type_id 
 	  	  	  	 JOIN event_configuration c on  ec_id = @EcId
 	  	  	  	 JOIN event_configuration_data d on d.ec_id = c.ec_id and d.ed_field_id = f.ed_field_id 
 	  	  	  	 JOIN event_configuration_values v on v.ecv_id = d.ecv_id
 	  	  	  	 JOIN ed_attributes a On d.ED_Attribute_Id = a.ED_Attribute_Id
 	  	  	  	 JOIN sampling_type s on s.ST_Id = d.St_Id
 	  	  	  	 Where c.EC_Id = @EcId and d.PU_Id = @PUId And f.ed_field_type_id = 3 	 --Tag
 	  	  	  	 Order by len(Alias),Alias
END
ELSE IF  @ModelNum = 803 --Production Event 
BEGIN
 	  	  	 SELECT d.ecv_id,f.ed_field_id,Alias , d.PU_Id, value = substring(convert(nvarchar(255),Value),4,LEN(convert(nvarchar(255),Value))),Attribute_Desc, ST_Desc, IsTrigger = isnull(IsTrigger,0), Sampling_Offset, Input_Precision
 	  	  	  	 FROM ed_fields f 
 	  	  	  	 JOIN ed_fieldtypes t on f.ed_field_type_id = t.ed_field_type_id 
 	  	  	  	 JOIN event_configuration c on  ec_id = @EcId
 	  	  	  	 JOIN event_configuration_data d on d.ec_id = c.ec_id and d.ed_field_id = f.ed_field_id 
 	  	  	  	 JOIN event_configuration_values v on v.ecv_id = d.ecv_id
 	  	  	  	 JOIN ed_attributes a On d.ED_Attribute_Id = a.ED_Attribute_Id
 	  	  	  	 JOIN sampling_type s on s.ST_Id = d.St_Id
 	  	  	  	 Where c.EC_Id = @EcId and d.PU_Id = @PUId And f.ed_field_type_id = 3 	 --Tag
 	  	  	  	 Order by len(Alias),Alias
END
ELSE
BEGIN
 	 Select Empty_Result_Set = 1
 	  	 Where 1=2
 	 Select Empty_Result_Set = 2
 	  	 Where 1=2
END

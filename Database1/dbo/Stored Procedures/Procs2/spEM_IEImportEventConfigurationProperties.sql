CREATE PROCEDURE dbo.spEM_IEImportEventConfigurationProperties
 	 @PL_Desc 	  	  	 nvarchar(50),
 	 @PU_Desc 	  	  	 nvarchar(50),
 	 @ET_Desc 	  	  	 nvarchar(50),
 	 @Input_Name 	  	  	 nvarchar(50),
 	 @Model_Number 	  	 nVarChar(10),
 	 @ModelDesc 	  	  	 nvarchar(255), 
 	 @Source_PU_Desc 	  	 nvarchar(50),
 	 @Field_Desc 	  	  	 nvarchar(255), 
 	 @Field_Order 	  	 nVarChar(10),
 	 @Field_Type_Desc 	 nvarchar(50),
 	 @Alias 	  	  	  	 nvarchar(50),
 	 @IsTrigger 	  	  	 nVarChar(10),
 	 @Attribute_Desc 	  	 nvarchar(50),
 	 @ST_Desc 	  	  	 nvarchar(50),
 	 @Sampling_Offset 	 nVarChar(10),
 	 @Input_Precision 	 nVarChar(10),
 	 @Value 	  	  	  	 varchar(8000),
 	 @Value1 	  	  	  	 nvarchar(50),
 	 @Value2 	  	  	  	 nvarchar(50),
 	 @IsUD 	  	  	  	 nVarChar(10),
 	 @User_Id 	  	  	 int
AS
Declare 	 @PL_Id int,@PU_Id int,@ET_Id int,@Source_PU_Id int,@Field_Id int,@Field_Type_Id int,@EC_Id int,@ED_Model_Id int,
 	  	 @PEI_Id int,@ECV_Id int,@ED_Attribute_Id int,@ST_Id int,@ED_Field_Type_Id int,@Max_Instances int,@iTrigger Int,@iSOffset Int,@iPrecision Int,
 	  	 @ValPUID  Int,@ValPLId 	 Int,@ValVarID Int,@Id Int,@Optional Int,@iUD Int
Declare @Prefix nVarChar(10)
DECLARE @ModelCount 	 Int
Select 	 @ECV_Id = Null,@PL_Id = Null,@PU_Id = Null,@ET_Id = Null,@Source_PU_Id = Null,@Field_Id = Null,@Field_Type_Id = Null,@EC_ID = Null,
 	  	 @ED_Model_Id = Null,@PEI_Id = Null,@ST_Id = Null,@ED_Attribute_Id = Null
/* Clean Arguments */
Select 	 @PL_Desc 	  	 = nullif(ltrim(rtrim(@PL_Desc)), ''),
 	  	 @PU_Desc 	  	 = nullif(ltrim(rtrim(@PU_Desc)), ''),
 	  	 @ET_Desc 	  	 = nullif(ltrim(rtrim(@ET_Desc)), ''),
 	  	 @Input_Name 	  	 = nullif(ltrim(rtrim(@Input_Name)), ''),
 	  	 @Model_Number 	 = nullif(ltrim(rtrim(@Model_Number)), ''),
 	  	 @ModelDesc 	  	 = nullif(ltrim(rtrim(@ModelDesc)), ''),
 	  	 @Source_PU_Desc 	 = nullif(ltrim(rtrim(@Source_PU_Desc)), ''),
 	  	 @Field_Desc 	  	 = nullif(ltrim(rtrim(@Field_Desc)), ''),
 	  	 @Field_Order 	 = nullif(ltrim(rtrim(@Field_Order)), ''),
 	  	 @Field_Type_Desc= nullif(ltrim(rtrim(@Field_Type_Desc)), ''),
 	  	 @Alias 	  	  	 = nullif(ltrim(rtrim(@Alias)), ''),
 	  	 @IsTrigger 	  	 = nullif(ltrim(rtrim(@IsTrigger)), ''),
 	  	 @IsUD 	  	  	 = nullif(ltrim(rtrim(@IsUD)), ''),
 	  	 @Attribute_Desc 	 = nullif(ltrim(rtrim(@Attribute_Desc)), ''),
 	  	 @ST_Desc 	  	 = nullif(ltrim(rtrim(@ST_Desc)), ''),
 	  	 @Sampling_Offset= nullif(ltrim(rtrim(@Sampling_Offset)), ''),
 	  	 @Input_Precision= nullif(ltrim(rtrim(@Input_Precision)), ''),
 	  	 @Value 	  	  	 = nullif(ltrim(rtrim(@Value)), ''),
 	  	 @Value1 	  	  	 = nullif(ltrim(rtrim(@Value1)), ''),
 	  	 @Value2 	  	  	 = nullif(ltrim(rtrim(@Value2)), '')
     /******************************************************************************************************************************************************
     *  	  	  	  	  	  	 Get Configuration Ids 	  	  	  	  	  	  	 *
     ******************************************************************************************************************************************************/
     -- Production Line, Unit and Location
     Select @PL_Id = PL_Id From Prod_Lines Where PL_Desc = @PL_Desc
 	  If @PL_Id is null
 	    Begin
 	  	 Select 'Failed - Production Line Not Found'
 	  	 Return(-100)
 	    End
     Select @PU_Id = PU_Id From Prod_Units Where PU_Desc = @PU_Desc And PL_Id = @PL_Id
     If @PU_Id Is Null
 	    Begin
 	  	 Select 'Failed - Production Unit Not Found'
 	  	 Return(-100)
 	    End
     If @Source_PU_Desc Is Not Null
       Begin
          Select @Source_PU_Id = PU_Id From Prod_Units Where PU_Desc = @Source_PU_Desc And PL_Id = @PL_Id
          If @Source_PU_Id Is Null
 	  	     Begin
 	  	  	  Select 'Failed - Location Not Found'
 	  	  	  Return(-100)
 	  	     End
 	  	 End
     Else
       Select @Source_PU_Id = @PU_Id
     -- Event Type
     Select @ET_Id = ET_Id  From Event_Types Where ET_Desc = @ET_Desc
     If @ET_Id Is Null
      Begin
 	  	 Select 'Failed - Invalid event type'
 	  	 Return (-100) 	 
      End
     -- Model id
     Select @ED_Model_Id = ED_Model_Id From ED_Models  Where Model_Num = @Model_Number
     If @ED_Model_Id Is Null
      Begin
 	  	 Select 'Failed - Invalid model number'
        Return (-100) 	 
      End
     -- Input for genealogy
     If @ET_Id In (16, 17, 18) 	  	 -- Input Movement, Genealogy, Consumption
      Begin
          Select @PEI_Id = PEI_Id From PrdExec_Inputs Where PU_Id = @PU_Id And Input_Name = @Input_Name
          If @PEI_Id Is Null
           Begin
             Select 'Failed - Invalid genealogy input'
             Return (-100) 	 
           End
          -- Event Configuration Id
          Select @EC_Id = EC_Id From Event_Configuration Where PU_Id = @PU_Id And ET_Id = @ET_Id And PEI_Id = @PEI_Id And ED_Model_Id = @ED_Model_Id
       End
     Else
       Begin
          -- Event Configuration Id
          Select @ModelCount = count(*)
 	  	  	 From Event_Configuration ec
 	  	  	 Join ed_Models ed on ed.ED_Model_Id =  ec.ED_Model_Id
 	  	  	 Where PU_Id = @PU_Id And ec.ET_Id = @ET_Id And ec.ED_Model_Id = @ED_Model_Id and (ec.EC_Desc = @ModelDesc or (ec.EC_Desc Is Null and ed.Model_Desc = @ModelDesc))
 	  	   IF @ModelCount > 1
 	  	   BEGIN
 	  	  	   Select 'Failed -  Multiple models with same description found'
 	  	  	   Return (-100) 	 
 	  	   END
          Select @EC_Id = EC_Id
 	  	  	 From Event_Configuration ec
 	  	  	 Join ed_Models ed on ed.ED_Model_Id =  ec.ED_Model_Id
 	  	  	 Where PU_Id = @PU_Id And ec.ET_Id = @ET_Id And ec.ED_Model_Id = @ED_Model_Id and (ec.EC_Desc = @ModelDesc or (ec.EC_Desc Is Null and ed.Model_Desc = @ModelDesc))
       End
     If @EC_Id Is Null
       Begin
          Select 'Failed -  Invalid event configuration/model assignment'
          Return (-100) 	 
       End
 	 If @IsUD = '1' 
 	  	 Select @iUD = 1
 	 Else
 	  	 Select @iUD = 0
 	 If @iUD = 0
 	 BEGIN
 	      Select 	 @Field_Id = ED_Field_Id,@ED_Field_Type_Id = ED_Field_Type_Id,@Max_Instances 	 = Max_Instances,
 	  	  	  	  	 @Optional = Optional
 	  	  	   From ED_Fields
 	  	      Where ED_Model_Id = @ED_Model_Id And Field_Desc = @Field_Desc And Field_Order = @Field_Order
 	  	      
 	 END
 	 ELSE
 	 BEGIN
 	      Select 	 @Field_Id = ED_Field_Prop_Id,@ED_Field_Type_Id = ED_Field_Type_Id,@Max_Instances= 1,
 	  	  	  	  	 @Optional = Optional
 	  	  	   From ED_Field_Properties
 	  	      Where ED_Model_Id = @ED_Model_Id And Field_Desc = @Field_Desc
 	  	 If @Field_Id Is Null
 	  	 BEGIN
 	  	  	 EXECUTE spEMED_PutUserDefined 
 	  	  	  	   @Value,
 	  	  	  	   0,
 	  	  	  	   0,
 	  	  	  	   1, --default to text
 	  	  	  	   @Field_Desc,
 	  	  	  	   @ED_Model_Id,
 	  	  	  	   @User_Id,
 	  	  	  	   @Field_Id Output
 	  	 END
 	 END
     If @Field_Id Is Null
       Begin
          Select  'Failed -  Invalid model field'
          Return (-100) 	 
       End
 	 Select @Prefix = Prefix From ED_Fieldtypes where ED_Field_Type_Id = @ED_Field_Type_Id
/*******************************/
/***Convert To Correct value ***/
/*******************************/
 	  If @ED_Field_Type_Id = 9 or @ED_Field_Type_Id = 10 -- Unit_Id / Var_Id
 	   Begin
 	  	 Select @ValPLId = PL_Id from Prod_Lines where PL_Desc = @Value
 	  	 If @ValPLId is null and @Optional = 0
 	  	   Begin
            Select  'Failed -  Production line for value not found'
            Return (-100) 	 
 	  	   End 
 	  	 Select @ValPUID = PU_Id From Prod_Units where pu_Desc = @Value1 and PL_Id = @ValPLId
 	  	 If @ValPUID is null and @Optional = 0
 	  	   Begin
            Select  'Failed -  Production Unit for value not found'
            Return (-100) 	 
 	  	   End
 	  	 If @ED_Field_Type_Id = 10
 	  	   Begin
 	  	  	 Select @ValVarID = Var_Id From Variables where Var_Desc = @Value2 and PU_Id = @ValPUId
 	  	  	 If @ValVarID is null and @Optional = 0
 	  	  	   Begin
 	             Select  'Failed -  Production Variable for value not found'
 	             Return (-100) 	 
 	  	  	   End
 	  	  	   Select @Value = Convert(nVarChar(10),@ValVarID)
 	  	   End
 	  	 Else
 	  	   Select @Value = Convert(nVarChar(10),@ValPUID)
 	   End
         If @ED_Field_Type_Id = 3 --Tag
          Begin
           Select @Value = dbo.fnEM_ConvertTagToVarId(@Value)
          End
 	  Select @Id = Null
 	  If @Prefix Is not Null
 	   Begin
 	  	 Select @Value = @Prefix + replace(@Value,@Prefix,'')
 	   End
 	  If @ED_Field_Type_Id = 8 -- SamplingType
 	   Begin
        Select @Id = ST_Id From Sampling_Type Where ST_Desc = @Value
        If @Id Is Null and @Optional = 0
          Begin
           Select  'Failed - Sampling type for value not found'
           Return (-100) 	 
          End
 	  	 Select @Value = Convert(nVarChar(10),@Id)
 	   End
 	  If @ED_Field_Type_Id = 15 -- Reason
 	   Begin
        Select @Id = Event_Reason_Id From event_reasons Where Event_Reason_Name = @Value
        If @Id Is Null and @Optional = 0
          Begin
           Select  'Failed - Reason Name for value not found'
           Return (-100) 	 
          End
 	  	 Select @Value = Convert(nVarChar(10),@Id)
 	   End
 	  If @ED_Field_Type_Id = 16 -- Production Status
 	   Begin
        Select @Id = ProdStatus_Id From production_Status Where ProdStatus_Desc = @Value
        If @Id Is Null and @Optional = 0
          Begin
           Select  'Failed - Production Status for value not found'
           Return (-100) 	 
          End
 	  	 Select @Value = Convert(nVarChar(10),@Id)
 	   End
 	  If @ED_Field_Type_Id = 6 -- Store True/False
 	   Begin
 	    If @Value = '1' 
 	  	 Select @Value = 'TRUE' 
 	    Else
 	  	 Select @Value = 'FALSE'
 	   End
     -- Sampling type
     If @ST_Desc Is Not Null
      Begin
      -- Sampling Type
        Select @ST_Id = ST_Id From Sampling_Type Where ST_Desc = @ST_Desc
        If @ST_Id Is Null 
          Begin
           Select  'Error: Invalid sampling type'
           Return (-100) 	 
          End
      End
     -- Attribute
     If @Attribute_Desc Is Not Null
      Begin
        -- Sampling Type
        Select @ED_Attribute_Id = ED_Attribute_Id From ED_Attributes  Where Attribute_Desc = @Attribute_Desc
        If @ED_Attribute_Id Is Null
         Begin
           Select 'Error: Invalid attribute'
           Return (-100) 	 
         End
      End
 	 If @Alias IS Not Null
 	 BEGIN
 	  	 If @Alias In ('AS','AT','BY','DO','FV','GO','IF','IN','IS','ME','NO','OF','ON','OR','PV','TO','THEN','ELSE')
 	  	 Begin
 	  	  	 Select 'Error: Invalid Alias'
 	  	  	 Return (-100) 	 
 	  	 End
 	 END
     /******************************************************************************************************************************************************
     *  	  	  	  	  	  	 Create Event Configuration Value 	  	  	  	  	  	 *
     ******************************************************************************************************************************************************/
     If @Max_Instances > 1
       Begin
            If @ED_Field_Type_Id = 3 	  	 -- Input Tag
            BEGIN
                 Select 	 @iSOffset = isnull(Convert(Int,@Sampling_Offset), 0),@ED_Attribute_Id 	 = isnull(@ED_Attribute_Id, 1), 	 -- Value
 	  	  	  	  	  	 @ST_Id 	  	  	 = isnull(@ST_Id, 12), 	  	 -- Last Good Value
 	  	  	  	  	  	 @IsTrigger 	  	 = isnull(@IsTrigger, 1),
 	  	  	  	  	  	 @Alias 	  	  	 = isnull(@Alias, 'A')
                 Select @ECV_Id = ECV_Id
                   From Event_Configuration_Data
                   Where EC_Id = @EC_Id And PU_Id = @PU_Id And ED_Field_Id = @Field_Id And (Alias = @Alias Or Alias Is Null)
            END
            Else If @ED_Field_Type_Id In (19, 20) 	 -- Status Script, Fault Script stored on sourcepu - 1 script / pu
                 Begin
 	  	  	  	   SELECT @Source_PU_Id = Isnull(@Source_PU_Id,@PU_Id)
 	  	  	       Select @ECV_Id = ECV_Id
                	  	 From Event_Configuration_Data
                	  	 Where EC_Id = @EC_Id And PU_Id = @Source_PU_Id And ED_Field_Id = @Field_Id 
                End
          	   Else If @ED_Field_Type_Id = 10 	 -- Variable Id
               Begin
                	  	 Select @ECV_Id = ecd.ECV_Id
                	  	 From Event_Configuration_Data ecd
                    Left Join Event_Configuration_Values ecv On ecd.ECV_Id = ecv.ECV_Id
                	  	 Where EC_Id = @EC_Id And PU_Id = @PU_Id And ED_Field_Id = @Field_Id And (ltrim(rtrim(convert(varchar(8000), ecv.Value))) = @Value Or ecv.Value Is Null)
               End
           	   Else If @ED_Field_Type_Id = 66 	 -- Event Property
               Begin
                	  	 Select @ECV_Id = ecd.ECV_Id
                	  	 From Event_Configuration_Data ecd
                    Left Join Event_Configuration_Values ecv On ecd.ECV_Id = ecv.ECV_Id
                	  	 Where EC_Id = @EC_Id And PU_Id = @PU_Id And ED_Field_Id = @Field_Id And (ltrim(rtrim(convert(varchar(8000), ecv.Value))) = @Value Or ecv.Value Is Null)
               End
         Else
             Begin
               Select  'Error: Unknown model configuration; Please configure manually'
               Return (-100)
             End
          Select @Input_Precision = isnull(@Input_Precision, 0)
          If @ECV_Id Is Null
            Begin
 	  	  	  	 SELECT @Source_PU_Id = Isnull(@Source_PU_Id,@PU_Id)
 	  	  	  	 Insert Into Event_Configuration_Values (Value) Values (@Value)
 	   	  	  	  	 select @ECV_Id = IDENT_CURRENT('event_configuration_values')
 	  	  	  	   Insert Into Event_Configuration_Data (EC_Id,ED_Field_Id,ECV_Id,PU_Id,Sampling_Offset,ED_Attribute_Id,ST_Id,IsTrigger,Input_Precision,Alias)
 	  	  	  	    Values ( 	 @EC_Id,@Field_Id,@ECV_Id,@Source_PU_Id,@Sampling_Offset,@ED_Attribute_Id,@ST_Id,@IsTrigger,@Input_Precision,@Alias)
 	  	  	  	 If @Value = Char(2)  Select Char(1) + convert(nVarChar(10),@ECV_Id)
            End
          Else
            Begin
               Update Event_Configuration_Data  Set PU_Id = @Source_PU_Id,Sampling_Offset = @Sampling_Offset,ED_Attribute_Id = @ED_Attribute_Id,
 	  	  	  	  	  	 ST_Id = @ST_Id,IsTrigger = @IsTrigger,Input_Precision = @Input_Precision,Alias 	 = @Alias
               Where ECV_Id = @ECV_Id
               If @@ROWCOUNT = 0
                 Begin
                    Select 'Error: Unable to update record'
                    Return (-100) 	 
                 End
 	  	  	    If @Value <> Char(2)
 	  	  	      Begin
                	   Update Event_Configuration_Values Set Value = @Value  Where ECV_Id = @ECV_Id
                	   If @@ROWCOUNT = 0
                    Begin
                      Select  'Error: Unable to update record'
                      Return (-100) 	 
                    End 	 
 	  	  	      End
 	  	  	   Else
 	  	  	    Begin
 	  	  	  	 Select Char(1) + convert(nVarChar(10),@ECV_Id)
 	  	  	  	 Return (-100) 	 
 	  	  	    End
             End
       End
     Else
       Begin
 	  	 If @iUD = 0
 	  	 BEGIN
 	           Select @ECV_Id = ECV_Id   From Event_Configuration_Data  Where EC_Id = @EC_Id And PU_Id = @PU_Id And ED_Field_Id = @Field_Id
 	           If @ECV_Id Is Not Null
 	             Begin
 	  	  	  	    If @Value = Char(2)
 	  	  	  	  	 Begin
 	  	  	  	  	  Select Char(1) + convert(nVarChar(10),@ECV_Id)
 	  	  	  	  	  Return(-100)
 	  	  	  	  	 End
 	  	  	  	    Else
 	  	  	  	  	 Begin
 	  	 /*DE106725,added update statment to Event_Configuration_Data table to update Input_Precision value (Input_Precision value is missing while import the production unit data)*/
 	  	  	 IF @ECV_id Is Not Null
 	  	  	 BEGIN
 	  	  	  	 UPDATE Event_Configuration_Data  Set Input_Precision = @Input_Precision
 	  	  	  	 WHERE ECV_Id = @ECV_Id and ed_field_id = @Field_Id
 	  	  	 END
 	                 	  	 Update Event_Configuration_Values  Set Value = @Value Where ECV_Id = @ECV_Id
 	  	                 If @@ROWCOUNT = 0
 	  	                  Begin
 	  	                     Select  'Error: Unable to update record'
 	  	                     Return (-100) 	 
 	  	                  End
 	  	  	  	  	 End
 	              End
 	           Else
 	             Begin
 	                Select  'Error: Missing model configuration records'
 	                Return (-100) 	 
 	             End
 	  	 END
 	  	 ELSE
 	  	 BEGIN
 	  	  	 DECLARE @DoUpdate Int
 	  	  	 SELECT @DoUpdate = EC_Id
 	  	  	  	 FROM Event_Configuration_Properties
 	  	  	  	 WHERE EC_Id = @EC_Id and  ED_Field_Prop_Id = @Field_Id
 	  	  	 IF @DoUpdate Is Null
 	  	  	  	 INSERT INTO Event_Configuration_Properties(EC_Id,ED_Field_Prop_Id,Value) VALUES (@EC_Id,@Field_Id,@Value)
 	  	  	 ELSE
 	  	  	  	 UPDATE Event_Configuration_Properties Set Value = @Value WHERE EC_Id = @EC_Id and  ED_Field_Prop_Id = @Field_Id
 	  	 END
 	 END
Return (0)

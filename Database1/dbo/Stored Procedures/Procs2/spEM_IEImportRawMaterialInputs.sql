CREATE PROCEDURE dbo.spEM_IEImportRawMaterialInputs
 	 @PLDesc 	  	 nvarchar(50),
 	 @PUDesc 	  	 nvarchar(50),
 	 @InputName 	 nvarchar(50),
 	 @EventSubType 	 nvarchar(50),
 	 @PrimSpec 	 nvarchar(150),
 	 @AltSpec 	 nvarchar(150),
 	 @Lock 	  	 nVarChar(10),
 	 @SourcePLDesc 	 nvarchar(50),
 	 @SourcePUDesc 	 nvarchar(50),
 	 @Status 	  	 nvarchar(50),
 	 @User_Id int
AS
Declare 
 	 @PUId 	  	 int, 
   	 @PLId 	  	 int,
 	 @SPUId 	  	 int, 
   	 @SPLId 	  	 int,
 	 @PSpecId 	 Int,
 	 @ASpecId 	 Int,
 	 @ESID 	  	 Int,
 	 @PEIId 	  	 Int,
 	 @Locked 	  	 Int,
 	 @EventStatus 	 Int,
 	 @Order 	  	 Int,
 	 @Index 	  	 Int,
 	 @PropDesc 	 nvarchar(50),
 	 @SpecDesc 	 nvarchar(50),
 	 @PropId 	  	 Int,
 	 @PEISId 	  	 Int
select @PLDesc  	  	 =  LTrim(RTrim(@PLDesc))
select @PUDesc  	  	 =  LTrim(RTrim(@PUDesc))
select @InputName  	 =  LTrim(RTrim(@InputName))
select @EventSubtype  	 =  LTrim(RTrim(@EventSubtype))
select @PrimSpec  	 =  LTrim(RTrim(@PrimSpec))
select @AltSpec  	 =  LTrim(RTrim(@AltSpec))
select @Lock  	  	 =  LTrim(RTrim(@Lock))
select @SourcePLDesc  	 =  LTrim(RTrim(@SourcePLDesc))
select @SourcePUDesc  	 =  LTrim(RTrim(@SourcePUDesc))
select @Status  	  	 =  LTrim(RTrim(@Status))
If @PLDesc = '' Select @PLDesc = Null
If @PUDesc = '' Select @PUDesc = Null
If @InputName = '' Select @InputName = Null
If @EventSubtype = '' Select @EventSubtype = Null
If @PrimSpec = '' Select @PrimSpec = Null
If @AltSpec = '' Select @AltSpec = Null
If @Lock = '' Select @Lock = Null
If @SourcePLDesc = '' Select @SourcePLDesc = Null
If @SourcePUDesc = '' Select @SourcePUDesc = Null
If @Status = '' Select @Status = Null
If @PLDesc IS NULL
BEGIN
 	 Select  'Production Line Not Found'
 	 Return(-100)
END
If @PUDesc IS NULL 
BEGIN
 	 Select  'Production Unit Not Found'
 	 Return(-100)
END
If @InputName IS NULL 
BEGIN
 	 Select  'Input Name Not Found'
 	 Return(-100)
END
Select @PLId = PL_Id from Prod_Lines
 	 Where PL_Desc = @PLDesc
If @PLId is Null
BEGIN
       Select  'Production Line Not Valid'
       Return(-100)
END
Select @PUId = PU_Id from Prod_Units 
 	 Where PU_Desc = @PUDesc  and PL_Id = @PLId
If @PUId IS NULL 
BEGIN
 	 Select  'Production Unit Not Found On Line'
 	 Return(-100)
END
Select @PEIId = PEI_Id 
From Prdexec_Inputs
WHERE Input_Name = @InputName AND PU_Id = @PUId
IF @PEIId Is NULL
BEGIN
 	 If isnumeric(@Lock) = 0 and @Lock is not null
 	 BEGIN
 	  	 SELECT 'Failed - Lock_Inprogress_Input is not correct '
 	  	 Return(-100)
 	 END 
 	 IF @Lock is Null
 	  	 SELECT @Locked = 1
 	 ELSE
 	  	 SELECT @Locked = Convert(bit,@Lock)
 	 SELECT @ESID = Event_Subtype_Id from Event_Subtypes where Event_Subtype_Desc = @EventSubType
 	 If @ESID IS NULL 
 	 BEGIN
 	  	 SELECT  'Event Subtype Not Found'
 	  	 Return(-100)
 	 END
 	 IF @PrimSpec Is Not Null
 	 BEGIN 	  	  	 
 	  	 SELECT @Index = CharIndex('/', @PrimSpec)
 	  	 If @Index > 0
 	  	 BEGIN
 	  	  	 Select @PropDesc = Left(@PrimSpec, @Index-1)
 	  	  	 Select @SpecDesc = Right(@PrimSpec, Len(@PrimSpec)- @Index)
 	  	  	 Select @PropId = Prop_Id
 	  	  	  	 From Product_Properties
 	  	  	  	 Where Prop_Desc = RTrim(LTrim(@PropDesc))
 	  	  	 Select @PSpecId = Spec_Id
 	  	  	  	 From Specifications
 	  	  	  	 Where Prop_Id = @PropId And Spec_Desc = RTrim(LTrim(@SpecDesc))
 	 
 	  	  	 If @PSpecId Is Null
 	  	  	 BEGIN
 	  	  	  	 Select 'Failed - invalid specification variable'
 	  	  	  	 Return(-100) 
 	  	  	 END
 	  	 END
 	  	 ELSE
 	  	 BEGIN
 	  	  	 Select 'Failed - invalid property/specification variable'
 	  	  	 Return(-100) 
 	  	 END
 	 END
 	 IF @AltSpec Is Not Null
 	 BEGIN
 	  	 SELECT @Index = 0,@PropId = Null
 	  	 Select @Index = CharIndex('/', @AltSpec)
 	  	 If @Index > 0
 	  	 BEGIN
 	  	  	 Select @PropDesc = Left(@AltSpec, CharIndex('/', @AltSpec)-1)
 	  	  	 Select @SpecDesc = Right(@AltSpec, Len(@AltSpec)- CharIndex('/', @AltSpec))
 	  	  	 Select @PropId = Prop_Id
 	  	  	  	 From Product_Properties
 	  	  	  	 Where Prop_Desc = RTrim(LTrim(@PropDesc))
 	  	  	 Select @ASpecId = Spec_Id
 	  	  	  	 From Specifications
 	  	  	  	 Where Prop_Id = @PropId And Spec_Desc = RTrim(LTrim(@SpecDesc))
 	 
 	  	  	 If @ASpecId Is Null
 	  	  	 BEGIN
 	  	  	  	 Select 'Failed - invalid specification variable'
 	  	  	  	 Return(-100) 
 	  	  	 END
 	  	 END
 	  	 ELSE
 	  	 BEGIN
 	  	  	 Select 'Failed - invalid property/specification variable'
 	  	  	 Return(-100) 
 	  	 END
 	 END
 	 SELECT @Order = Max(Input_Order) From prdexec_inputs Where PU_Id = @PUId
 	 SELECT @Order = isnull(@Order,1)
 	 INSERT INTO prdexec_inputs(Input_Name, Input_Order, PU_Id, Event_Subtype_Id, Primary_Spec_Id, Alternate_Spec_Id, Lock_Inprogress_Input)
 	  	 VALUES (@InputName, @Order, @PUId, @ESID, @PSpecId, @ASpecId, @Locked)
 	 SELECT @PEIId = Scope_Identity()
 	 IF @PEIId is Null
 	 BEGIN
 	  	 Select 'Failed - Unable to create input'
 	  	 Return(-100) 
 	 END
 	 
END
IF @Status Is Not Null
BEGIN
 	 If @SourcePLDesc IS NULL
 	 BEGIN
 	  	 Select  'Source Production Line Not Found'
 	  	 Return(-100)
 	 END
 	 If @SourcePUDesc IS NULL 
 	 BEGIN
 	  	 Select  'Source Production Unit Not Found'
 	  	 Return(-100)
 	 END
 	 
 	 Select @PLId = Null
 	 Select @PLId = PL_Id from Prod_Lines
 	  	 Where PL_Desc = @SourcePLDesc
 	 If @PLId is Null
 	 BEGIN
 	        Select  'Source Production Line Not Valid'
 	        Return(-100)
 	 END
 	 
 	 Select @PUId = Null
 	 Select @PUId = PU_Id from Prod_Units 
 	  	 Where PU_Desc = @SourcePUDesc and PL_Id = @PLId
 	 If @PUId IS NULL 
 	 BEGIN
 	  	 Select  'Source Production Unit Not Found On Source Line'
 	  	 Return(-100)
 	 END 	 
 	 SELECT @PEISId = PEIS_Id
 	  	 FROM PrdExec_Input_Sources
 	  	 WHERE PEI_Id = @PEIId AND PU_Id = @PUId
 	 If @PEISId Is Null
 	 BEGIN
 	  	 INSERT INTO PrdExec_Input_Sources(PEI_Id,PU_Id) Values (@PEIId,@PUId)
 	  	 SELECT @PEISId = Scope_Identity()
 	 END
 	 SELECT @EventStatus = ProdStatus_Id 
 	  	 FROM Production_Status
 	  	 WHERE ProdStatus_Desc = @Status
 	 If @EventStatus Is Null
 	 BEGIN
 	  	 Select  'Production Status Not Found'
 	  	 Return(-100)
 	 END
 	 IF (NOT EXISTS(SELECT PEIS_Id FROM PrdExec_Input_Source_Data WHERE PEIS_Id = @PEISId and Valid_Status = @EventStatus))
 	 BEGIN
 	  	 INSERT INTO PrdExec_Input_Source_Data(PEIS_Id,Valid_Status) VALUES(@PEISId,@EventStatus)
 	 END
END
RETURN(0)

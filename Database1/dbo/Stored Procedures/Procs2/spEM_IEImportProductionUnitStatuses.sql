CREATE PROCEDURE dbo.spEM_IEImportProductionUnitStatuses
 	 @PLDesc 	  	 nvarchar(50),
 	 @PUDesc 	  	 nvarchar(50),
 	 @Status 	  	 nvarchar(50),
 	 @IsDefault 	 nVarChar(10),
 	 @ValidTrans 	 nvarchar(50),
 	 @User_Id int
AS
Declare 
 	 @PUId 	  	  	 int, 
   	 @PLId 	  	  	 int,
 	 @IsDefaulted 	  	 Int,
 	 @EventStatus 	  	 Int,
 	 @EventStatusTrans 	 Int,
 	 @PEXPId 	  	  	 Int
select @PLDesc  	  	 =  LTrim(RTrim(@PLDesc))
select @PUDesc  	  	 =  LTrim(RTrim(@PUDesc))
select @IsDefault  	 =  LTrim(RTrim(@IsDefault))
select @Status  	  	 =  LTrim(RTrim(@Status))
select @ValidTrans  	 =  LTrim(RTrim(@ValidTrans))
If @PLDesc = '' Select @PLDesc = Null
If @PUDesc = '' Select @PUDesc = Null
If @IsDefault = '' Select @IsDefault = Null
If @Status = '' Select @Status = Null
If @ValidTrans = '' Select @ValidTrans = Null
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
SELECT @EventStatus = ProdStatus_Id 
 	 FROM Production_Status
 	 WHERE ProdStatus_Desc = @Status
If @EventStatus Is Null
BEGIN
 	 Select  'Production Status Not Found'
 	 Return(-100)
END
SELECT @PEXPId = PEXP_Id from  PrdExec_Status Where PU_Id = @PUId and Valid_Status = @EventStatus
IF @PEXPId Is NULL
BEGIN
 	 If isnumeric(@IsDefault) = 0 and @IsDefault is not null
 	 BEGIN
 	  	 SELECT 'Failed - Is Default is not correct '
 	  	 Return(-100)
 	 END 
 	 IF @IsDefault is Null
 	  	 SELECT @IsDefaulted = 0
 	 ELSE
 	  	 SELECT @IsDefaulted = Convert(bit,@IsDefault)
 	 INSERT INTO PrdExec_Status(Is_Default_Status,PU_Id,Step,Valid_Status) VALUES(@IsDefaulted,@PUId,1,@EventStatus)
END
IF @ValidTrans Is Not NULL
BEGIN 
 	 SELECT @EventStatusTrans = ProdStatus_Id 
 	  	 FROM Production_Status
 	  	 WHERE ProdStatus_Desc = @ValidTrans
 	 If @EventStatusTrans Is Null
 	 BEGIN
 	  	 Select  'Valid Production Status Not Found'
 	  	 Return(-100)
 	 END
 	 IF (NOT EXISTS(SELECT PET_Id FROM PrdExec_Trans WHERE From_ProdStatus_Id = @EventStatus and PU_Id = @PUId and To_ProdStatus_Id = @EventStatusTrans))
 	 BEGIN
 	  	 INSERT INTO PrdExec_Trans(PU_Id,From_ProdStatus_Id,To_ProdStatus_Id) VALUES(@PUId,@EventStatus,@EventStatusTrans)
 	 END
END
RETURN(0)

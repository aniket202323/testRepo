  /*  
Stored Procedure: dbo.spLocal_Parts_SpeedsTransactions  
Author:   Francis Osorno  
Date Created:  Feb 27, 2006  
  
Description:  
=========  
This sp will load speed targets from PARTS into the correct Plant Applications tables and ALTER  aPlant Applications trands_desc to allow updating of PARTS  
   
Change Date  Who  What  
=========== ==== =====  
Feb  27, 2006  FGO  Created procedure  
Mar 14, 2006  FGO  Modified to deliver the required results  
Mar 16, 2006  FGO  Totally done with phase one coding   
Mar 21, 2006  FGO  Added the Insert TransType  
         Added messages to the event log for trans types that are not programed  
May 10, 2006  FGO  Tested Code and added the linking of the products to the Rate Loss Unit and assigning of the characteristic to the unit product  
May 12, 2006  FGO  updated the code for when no Spec_Precision is in the database default to precision 2  
May 22, 2006  FGO  Adding in the email notification code  
June 05, 2006  FGO  Updated the code to set the new product to all master units of the line when it is not assigned already  
Aug 07, 2006  FGO  corrected the eng/units to the standard  
         updated for the use of Use Email Engine Variable  
March 29, 2007  FGO  updated for better  error checking  
         added the Local Table for the update back to PARTS  
         added with(nolock) to all dbo joins  
April 26, 2007  FGO  updated for  PARTS change that was no communicated for 'CONV_IDEAL_SPEEDS_BB' to 'CONV_IDEAL_SPEEDS'  
May 10, 2006  FGO  updated to not process data if @EffDatea >= getdate + 1  
         also corrected the end command on the error checking to end even if no email is used  
June 21, 2007  FGO  changed the conversion of fpm to mpm from .3058 to .3048  
         also will update the Ideal speed for UOM   
         added URL limits to Target Speed to 102% of target  
         change the LRL to 98% of target rather than 97%  
July 20, 2007  FGO  Updated the email code to allow only certian messages to be sent based on email users in the group  
         changed the target speed code check to allow for only a target change difference to allow updating the spec  
Aug 27, 2007  FGO  modified the DELETE code to insert only if cahr_id is not null  
21-MAY-2008   FLD  Modified Eff_Date threshold for processing from GetDate() + 1 to GetDate() + 10 to be consistent  
         with what is on the PARTS side and to allow sufficient lead time to process backlogs or   
         records with a "future" date.  
  
*/  
  
CREATE                procedure dbo.spLocal_Parts_SpeedsTransactions  
--DECLARE  
 @success             int  OUTPUT,    --this is the sucess message  
 @errmsg              varchar(255) OUTPUT, --this is the errmsg  
 @confstring           varchar(255) OUTPUT, -- this the is he conf string for the event  
-- @success             int,      --this is the sucess message  
-- @errmsg              varchar(255),   --this is the errmsg  
-- @confstring           varchar(255),   -- this the is he conf string for the event  
 @NewBrandCode          varchar(9),       --this is the brandcode of the record to deal with  
 @NewResourceID       varchar(6),    --this is the Line of the record to deal with  
 @NewLineSpeed        float(3),     --this is the new speed to deal with for the record  
 @EffDate   datetime,    --this is the Effective date of the specification  
 @OldLineSpeed  float(3),     --this is the old line speed to deal with for the record  
 @OldEffDate   datetime,    --the effective date of the old line speed  
 @TransTable          varchar(35),    --this is the type of record to deal with  
 @TransType   varchar(12),    --this is the type of PARTS Transaction  
             --Update this is an update to either the effective date or speed  
              --Auto Job is a new record  
              --Delete is a removal of the data in Plant Applications and and  
               --reset to the old data  
               --Insert will be a straight insert  
 @OracleTransID      varchar(10)    --this is the Oracle Transid that will be build into the Proficy trans_desc            
  
               
 /* Testing code */  
/*  
 SELECT --@NewBrandCode = '84902741',  
       @NewBrandCode = '84956650B',  
   --@NewBrandCode = 'fgo',  
   @NewResourceID = 'fff6',  
   @NewLineSpeed = 93.33,  
--   @TransTable = 'CONV_TRGT',  
   @TransTable = 'CONV_IDEAL_SPEEDS',  
   @TransType = 'insert',  
   @OracleTransID = '63196',  
--   @OldLineSpeed  = 1183,   
--   @OldEffDate = '3/1/06',  
   @EffDate = '7/1/01'  
*/  
   
  
AS  
  
/*Variable table */  
DECLARE @Data TABLE(  
  ResourceName    varchar(25), --the unit name header  
  Brand     varchar(9), --the char_desc  
  Spec     varchar(25), --the speification to update  
  eng_Units    varchar(50), --it's eng units  
  Spec_Data_Type  varchar(25),   --it's data type  
  Spec_Precision   int,   --it's precision  
  target     varchar(25), --it's target  
  EffDate     datetime,  --it's effective date  
  OldTarget    varchar(25), --it's old target  
  OldEffDate    datetime,  --it's old effective date  
  LRL      varchar(25), --it's LRL  
  URL      varchar(25), --it's URL  
  prop_id     int,   --it's prop_id  
  AllBrands_CharID  int,   --this is the All Brands Char_ID of the property  
  NeedsTreeUpdate  int default(0), --does the tree need updating 0 no  
  RL_puid     int,   --this is the rateloss puid  
  char_id     int,   --it's char_id  
  spec_id     int,   --it's spec_id  
  Current_Ideal   varchar(25), --it's current Line Speed Ideal  
  Current_Target   varchar(25), --it's current Line Speed Target  
  Current_Target_LRL  varchar(25), --it's current Line Speed Target LRL  
  Current_Target_URL  varchar(25), --it's current Line Speed Target URL  
  Last_Ideal    varchar(25), --it's last Line Speed Ideal  
  Last_Target    varchar(25), --it's last Line Speed Target  
  Last_Target_LRL  varchar(25), --it's last Line Speed Target LRL   
  Last_Target_URL  varchar(25) --it's last Line Speed Target URL   
 )  
  
/*declare the temp table for the unit ot product assignment */  
DECLARE @PUToP TABLE(  
  PUID  int,   --this the pu_id  
  ProdID  int   --the prod_id from pu_products  
 )  
/*declare the variables */  
 DECLARE  
  @UserID  int,    --the user id to use  
  @TransID  int,    --the trancation id  
  @TransDesc  varchar(50),  --the tranaction description  
  @TransDesc1 varchar(50),  --the tranaction description for tree updates  
  @TransGrp  int,    --the tranaction group  
  @ApproveDate datetime,  --Approved Date  
  @EffectiveDate datetime,  --Effective Date  
  @SpecDesc          varchar(35),  --this is the spec description  
  @OldTarget  varchar(25),  --this is the old target  
  @OldLRL  varchar(25),  --this is the old LRL  
  @OldURL  varchar(25),  --this is the old URL  
  @ProdID  int,    --this is the prod_id of the product for the new_brand_code   
  @errsufix  varchar(75),  --this is the standard sufix to @errmsg  
  @GenEMail  int,    --this is the General Email Error Group  
  @ProdEMail  int,    -- this is the Product Email  Error Group  
  @SpecsEmail int,    --this is the Specs Email Error Group  
  @SuccessEMail int,    --this is the Success Email Group  
  @GenProfEMail int,    --this is the General Proficy Email Group  
  @UseEmail  varchar(25),  --this is the value of Use Email Engine Yes write to Email Engine No do not write  
  @StrMsg  varchar(100), --this is the base  of the output message  
  @EffDateError int    --this is if @EffDate is greater than getdate() + 10 the varialbe will be set to 1 so the PARTS side will not be affected  
  
/* set the sufix to for @errmsg */  
  SELECT @errsufix = 'for Line: ' + left(@NewResourceID,len(@NewResourceID)) + ' Product: ' + @NewBrandCode + ' Oracle TransID: '+ @OracleTransID  
  
/*get the value of @UseEmail */  
 SELECT TOP 1  @UseEmail=t.result  
  FROM dbo.tests t with(nolock)  
   JOIN dbo.variables v with(nolock) ON v.var_id = t.var_id  
  WHERE v.var_desc = 'Use Email Engine'  
  ORDER BY t.result_on desc  
  
  
/* get all the EMail Group ID */  
IF upper(@UseEmail) = 'YES'  
 BEGIN  
  IF EXISTS(SELECT * FROM dbo.email_groups WHERE eg_desc = 'Server Notification (Critical)')  
   BEGIN  
    SELECT @GenProfEMail = eg_id FROM dbo.email_groups WHERE eg_desc = 'Server Notification (Critical)'  
   END  
  ELSE  
   BEGIN  
    SELECT @success =0  
    SELECT @strMsg = 'Email Engine for Proficy General Errors not Setup '   
    SELECT @errmsg = @strMsg + @errsufix  
    GOTO PlantAppsReturn  
   END  
  
  IF EXISTS(SELECT * FROM dbo.email_groups WHERE eg_desc = 'PARTS Speeds (PARTS Critical)')  
   BEGIN  
    SELECT @GenEMail = eg_id FROM dbo.email_groups WHERE eg_desc = 'PARTS Speeds (PARTS Critical)'  
   END  
  ELSE  
   BEGIN  
    SELECT @success =0  
    SELECT @strMsg = 'Email Engine for General Errors Group not Setup '  
    SELECT @errmsg = @strMsg + @errsufix  
    IF EXISTS(SELECT * FROM dbo.email_groups_data where eg_id = @GenProfEMail)  
     BEGIN  
      INSERT INTO dbo.email_messages(eg_id,submitted_on,em_subject,em_content)  
       VALUES(@GenProfEMail,getdate(),'PARTS Speed Email Group Does not Exit',@errmsg)  
     END  
    GOTO PlantAppsReturn  
   END  
  IF EXISTS( SELECT* FROM dbo.email_groups WHERE eg_desc = 'PARTS No Product (PARTS Critical)')  
   BEGIN  
    SELECT @ProdEMail = eg_id FROM dbo.email_groups WHERE eg_desc = 'PARTS No Product (PARTS Critical)'  
   END  
  ELSE  
   BEGIN   
    SELECT @success =0  
    SELECT @strMsg ='Email Engine for Product Errors Group not Setup '  
    SELECT @errmsg =  @strMsg + @errsufix  
    IF EXISTS(SELECT * FROM dbo.email_groups_data where eg_id = @GenProfEMail)  
     BEGIN  
      INSERT INTO dbo.email_messages(eg_id,submitted_on,em_subject,em_content)  
       VALUES(@GenProfEMail,getdate(),'PARTS Speed Email Group Does not Exit',@errmsg)  
     END  
    GOTO PlantAppsReturn  
   END  
  
  IF EXISTS( SELECT * FROM dbo.email_groups WHERE eg_desc = 'PARTS Specs (PARTS Warning)')  
   BEGIN  
    SELECT @SpecsEMail = eg_id FROM dbo.email_groups WHERE eg_desc = 'PARTS Specs (PARTS Warning)'  
   END  
  ELSE  
   BEGIN  
    SELECT @success =0  
    SELECT @strMsg = 'Email Engine for Product Errors Group not Setup '  
    SELECT @errmsg =  @strMsg + @errsufix  
    IF EXISTS(SELECT * FROM dbo.email_groups_data where eg_id = @GenProfEMail)  
     BEGIN  
      INSERT INTO dbo.email_messages(eg_id,submitted_on,em_subject,em_content)  
       VALUES(@GenProfEMail,getdate(),'PARTS Speed Email Group Does not Exit',@errmsg)  
     END  
    GOTO PlantAppsReturn  
   END  
  
  IF EXISTS(SELECT * FROM dbo.email_groups WHERE eg_desc = 'PARTS Speeds (PARTS Success)')  
   BEGIN  
    SELECT @SuccessEMail = eg_id FROM dbo.email_groups WHERE eg_desc = 'PARTS Speeds (PARTS Success)'  
   END  
  ELSE  
   BEGIN  
    SELECT @success =0  
    SELECT @strMSG = 'Email Engine for Success Group not Setup '  
    SELECT @errmsg = @strMsg + @errsufix  
    IF EXISTS(SELECT * FROM dbo.email_groups_data where eg_id = @GenProfEMail)  
     BEGIN  
      INSERT INTO dbo.email_messages(eg_id,submitted_on,em_subject,em_content)  
       VALUES(@GenProfEMail,getdate(),'PARTS Speed Email Group Does not Exit',@errmsg)  
     END  
    GOTO PlantAppsReturn  
   END  
 END  
  
/* if @EffDate > GetDate() + 10 then end */  
 SELECT @EffDateError =0  
 IF @EffDate > getdate() + 10  
  BEGIN  
  SELECT @Success = 0  
  SELECT @EffDateError =1  
  SELECT @strMsg ='The Effective Date is greater than allowed '  
  SELECT @errmsg =  @StrMsg + @errsufix  
  IF upper(@UseEmail) = 'YES'  
   BEGIN    
    IF EXISTS(SELECT * FROM dbo.email_groups_data where eg_id = @GenEMail)  
     BEGIN  
      INSERT INTO dbo.email_messages(eg_id,submitted_on,em_subject,em_content)  
       VALUES(@GenEMail,getdate(),'PARTS Speeds Incorrect Oracle TransType of: ' + @TransType ,@errmsg)  
     END  
   END  
  GOTO PlantAppsReturn  
 END  
  
   
/*  Determine what to do.      */  
  
 IF upper(@TransType) = 'AUTO_JOB'  or upper(@TransType) = 'INSERT' or  upper(@TransType) = 'DELETE' or upper(@TransType) = 'UPDATE' GOTO ContinueWork  
  
/*     Update the messages to show nothing was done*/  
  
IF upper(@UseEmail) = 'YES'  
 BEGIN  
  SELECT @Success = 0  
  SELECT @strMsg ='The Trans type requested will not process '  
  SELECT @errmsg =  @StrMsg + @errsufix  
  IF EXISTS(SELECT * FROM dbo.email_groups_data where eg_id = @GenEMail)  
   BEGIN  
    INSERT INTO dbo.email_messages(eg_id,submitted_on,em_subject,em_content)  
     VALUES(@GenEMail,getdate(),'PARTS Speeds Incorrect Oracle TransType of: ' + @TransType ,@errmsg)  
   END  
 END  
  
ContinueWork:  
/* verifiy that the user exists, if not exit.                          */  
  
 IF EXISTS(SELECT * FROM dbo.users WHERE username ='PARTS Speeds')  
  BEGIN  
   SELECT @UserID = user_id FROM dbo.users WHERE username ='PARTS Speeds'  
  END  
 ELSE  
  BEGIN  
   SELECT @success =0  
   SELECT @StrMsg = 'No PARTS Speeds User '  
   SELECT @errmsg =  @StrMsg+ @errsufix  
   IF upper(@UseEmail) = 'YES'  
    BEGIN  
     IF EXISTS(SELECT * FROM dbo.email_groups_data where eg_id = @GenEMail)  
      BEGIN  
       INSERT INTO dbo.email_messages(eg_id,submitted_on,em_subject,em_content)  
        VALUES(@GenEMail,getdate(),'PARTS Speeds General Error',@errmsg)  
      END  
    END  
   GOTO PlantAppsReturn  
    END  
  
/*  does the @newbrandcode exist in the database    */  
 IF EXISTS(SELECT * FROM dbo.products WHERE prod_code = @NewBrandCode)  
  BEGIN  
   SELECT @ProdID = prod_id FROM dbo.products WHERE prod_code = @NewBrandCode  
  END  
 ELSE  
  BEGIN  
   SELECT @success =0  
   SELECT @strMsg = 'Product not in Plant Applications '  
   SELECT @errmsg =  @StrMsg + @errsufix  
   IF upper(@UseEmail) = 'YES'  
    BEGIN  
     IF EXISTS(SELECT * FROM dbo.email_groups_data where eg_id = @ProdEMail)  
      BEGIN  
       INSERT INTO dbo.email_messages(eg_id,submitted_on,em_subject,em_content)  
        VALUES(@ProdEMail,getdate(),'PARTS Speed Load Product Error',@errmsg)  
      END  
    END  
   GOTO PlantAppsReturn  
    END  
  
/*  Verifiy that the transaction group exists, if not exit.          */  
  
 IF EXISTS(SELECT * FROM dbo.transaction_groups WHERE Transaction_Grp_Desc = 'PARTS Speeds Import')  
  BEGIN    
   SELECT  @TransGrp= transaction_grp_id FROM dbo.transaction_groups WHERE Transaction_Grp_Desc = 'PARTS Speeds Import'  
  END  
 ELSE  
  BEGIN  
   SELECT @success =0  
   SELECT @strMsg = 'No PARTS Speeds Import TG '  
   SELECT @errmsg =  @strMsg + @errsufix  
   IF upper(@UseEmail) = 'YES'  
    BEGIN  
     IF EXISTS(SELECT * FROM dbo.email_groups_data where eg_id = @GenEMail)  
      BEGIN  
       INSERT INTO dbo.email_messages(eg_id,submitted_on,em_subject,em_content)  
        VALUES(@GenEMail,getdate(),'PARTS Speeds General Error',@errmsg)  
      END  
    END  
   GOTO PlantAppsReturn  
  END  
  
/* Set @TransDate and @TransDesc */  
 SELECT @TransDesc = 'PARTS Speed ' + @OracleTransID  
  
/* Verify the transaction does not exist, if so exit */  
 IF EXISTS(SELECT trans_desc FROM dbo.transactions WHERE trans_desc = @TransDesc)   
  BEGIN  
   SELECT @success =0  
   SELECT @strMsg = 'Main Transaction exists already '  
   SELECT @errmsg =  @strMsg + @errsufix  
   IF upper(@UseEmail) = 'YES'  
    BEGIN  
     IF EXISTS(SELECT * FROM dbo.email_groups_data where eg_id = @GenEMail)  
      BEGIN  
       INSERT INTO dbo.email_messages(eg_id,submitted_on,em_subject,em_content)  
        VALUES(@GenEMail,getdate(),'PARTS Speeds General Error',@errmsg)  
      END  
    END  
   GOTO PlantAppsReturn  
  END  
  
  
/*  Determine which type of spec.                                     */  
  
 SELECT @SpecDesc =   
      Case  
          WHEN @TransTable  = 'CONV_IDEAL_SPEEDS' THEN 'Line Speed Ideal'   
          WHEN @TransTable  = 'CONV_TRGT' THEN 'Line Speed Target'  
          ELSE  
             'Incorrect Transaction Table'  
          END  
  
 IF @SpecDesc = 'Incorrect Transaction Table'     
    BEGIN  
        SELECT @strMsg = 'Invalid Spec Table name received from PARTS. The Spec table received was ' +  
                         @TransTable + ' This cannot be processed '  
 SELECT @errmsg =  @strMsg + @SpecDesc + ' ' + @errsufix  
 IF upper(@UseEmail) = 'YES'  
  BEGIN  
   IF EXISTS(SELECT * FROM dbo.email_groups_data where eg_id = @GenEMail)  
    BEGIN  
     INSERT INTO dbo.email_messages(eg_id,submitted_on,em_subject,em_content)  
      VALUES(@GenEMail,getdate(),'Incorrect Transaction Table',@errmsg)  
    END  
  END  
  GOTO PlantAppsReturn  
     END  
  
IF @TransTable = 'CONV_IDEAL_SPEEDS'   
   BEGIN  
      SELECT @SpecDesc = 'Line Speed Ideal'  
   END  
ELSE  
   BEGIN  
      SELECT @SpecDesc = 'Line Speed Target'  
   END  
   
IF @SpecDesc <> 'Line Speed Ideal' and @SpecDesc <> 'Line Speed Target'  
 BEGIN  
  SELECT @success =0  
  SELECT @strMsg= 'Incorrect Specification Description of: '  
  SELECT @errmsg =  @strMsg + @SpecDesc + ' ' + @errsufix  
  IF upper(@UseEmail) = 'YES'  
   BEGIN  
    IF EXISTS(SELECT * FROM dbo.email_groups_data where eg_id = @GenEMail)  
     BEGIN  
      INSERT INTO dbo.email_messages(eg_id,submitted_on,em_subject,em_content)  
       VALUES(@GenEMail,getdate(),'PARTS Speeds General Error',@errmsg)  
     END  
   END  
  GOTO PlantAppsReturn  
 END  
/*  Place the data into @Data temp table.                      */  
  
 INSERT INTO @Data(ResourceName,Brand,Spec,target,OldTarget,OldEffDate)  
  VALUES(@NewResourceID,@NewBrandCode,@SpecDesc,@NewLineSpeed,@OldLineSpeed,@OldEffDate)  
  
  
/*  Get all the base information.     */  
  
  
/******BEGIN updating @Data ********/  
  
 --Set the prop_id.  
 UPDATE d  
   SET prop_id = pp.prop_id  
  FROM @Data d  
   JOIN dbo.product_properties pp with(nolock) on pp.prop_desc = d.ResourceName + ' Production Factors'  
 IF EXISTS(SELECT * FROM @Data WHERE prop_id is null)  
  BEGIN  
   SELECT @success =0  
   SElECT @strMsg = 'Incorrect Resource Name from PARTS '  
   SELECT @errmsg = @strMsg + @errsufix  
   IF upper(@UseEmail) = 'YES'  
    BEGIN  
     IF EXISTS(SELECT * FROM dbo.email_groups_data where eg_id = @GenProfEMail)  
      BEGIN  
      INSERT INTO dbo.email_messages(eg_id,submitted_on,em_subject,em_content)  
       VALUES(@GenProfEMail,getdate(),'PARTS Speed Email Group Does not Exit',@errmsg)  
     END  
    END  
   GOTO PlantAppsReturn  
  END   
   
 --Set the spec_id, eng_units, spec_data_type and spec_precision.  
 UPDATE d  
  SET spec_id        = s.spec_id,  
   eng_units      = s.eng_units,  
   spec_data_type = dt.data_type_desc,  
   spec_precision = s.spec_precision  
  FROM @Data d  
   JOIN dbo.specifications s with(nolock)on s.spec_desc = d.spec and s.prop_id = d.prop_id  
   JOIN dbo.data_type dt with(nolock) on dT.data_type_id = s.data_type_id  
   
 --Update AllBrands_CharID.   
 UPDATE d  
  SET AllBrands_CharId = c.char_id  
  FROM @Data d  
   LEFT JOIN dbo.characteristics c with(nolock) ON c.prop_id = d.prop_id and c.char_desc = 'All Brands'  
   
 --Set the char_id.  
 UPDATE d  
  SET char_id = c.char_id  
  FROM @data d  
   JOIN dbo.characteristics c with(nolock) on c.char_desc = d.brand and c.prop_id = d.prop_id  
   
 UPDATE @Data  
  SET NeedsTreeUpdate = 1  
  WHERE char_id is null  
  
 --seeing getting the rate loss pu_id and get the product _id on the rate loss unit  
 UPDATE d  
  SET RL_puid = pu.pu_id  
  FROM @data d  
   LEFT JOIN dbo.prod_units pu with(nolock) on pu.pu_desc = ResourceName + ' Rate Loss'  
 --Get all the units of the line  
 INSERT INTO @PUToP(PUID)  
  SELECT pu.pu_id  
   FROM dbo.prod_units pu  
    LEFT JOIN dbo.prod_lines pl with(nolock) ON pl.pl_id = pu.pl_id  
   WHERE pl.pl_desc like '% ' + @NewResourceID and pu.master_unit is null  
 UPDATE @PUToP  
  SET ProdID = pup.prod_id  
 FROM @PUToP d  
  LEFT JOIN dbo.pu_products pup with(nolock) ON pup.pu_id = d.PUID  
 WHERE pup.prod_id = @ProdID  
  
 /*  
   Update the specifications for Line Target Speed only depending on the eng_units.   
     This is required since PARTS eng_units is always fpm.                                                  
     In Plant Applications the eng_units may be FPP or m/min for Line Target Speeds    
   This is also setting the precision based on the format in Plant APplications                
 */  
 UPDATE d  
  SET LRL =   
  CASE  
   WHEN d.eng_units = 'm/min' and d.Spec_Data_Type  = 'Integer' and  d.spec = 'Line Speed Target' THEN convert(varchar(25), convert(int,(convert(int,target))*.3048*.98))  
   WHEN d.eng_units = 'm/min' and d.Spec_Data_Type = 'Float' and d.spec = 'Line Speed Target' THEN CASE  
      WHEN d.Spec_Precision = 1 THEN convert(varchar(25), convert(float(1),(convert(float(1),target))*.3048*.98))  
      WHEN d.Spec_Precision = 2 THEN convert(varchar(25), convert(float(2),(convert(float(2),target))*.3048*.98))  
      WHEN d.Spec_Precision = 3 THEN convert(varchar(25), convert(float(3),(convert(float(3),target))*.3048*.98))  
      ELSE convert(varchar(25), convert(float(2),(convert(float(2),target))*.3048*.98))  
     END  
   WHEN d.eng_units = 'FPM' and d.Spec_Data_Type = 'Integer' and  d.spec = 'Line Speed Target'THEN convert(varchar(25), convert(int,(convert(int,target)*.98)))  
   WHEN d.eng_units = 'FPM' and d.Spec_Data_Type = 'Float' and d.spec = 'Line Speed Target' THEN CASE  
      WHEN d.Spec_Precision = 1 THEN convert(varchar(25), convert(float(1),(convert(float(1),target))*.98))  
      WHEN d.Spec_Precision = 2 THEN convert(varchar(25), convert(float(2),(convert(float(2),target))*.98))  
      WHEN d.Spec_Precision = 3 THEN convert(varchar(25), convert(float(3),(convert(float(3),target))*.98))  
      ELSE convert(varchar(25), convert(float(2),(convert(float(2),target))*.98))  
     END  
   WHEN d.eng_units = 'cuts/min' and d.Spec_Data_Type = 'Integer' and  d.spec = 'Line Speed Target'THEN convert(varchar(25), convert(int,(convert(int,target)*.98)))  
   WHEN d.eng_units = 'cuts/min' and d.Spec_Data_Type = 'Float' and d.spec = 'Line Speed Target' THEN CASE  
      WHEN d.Spec_Precision = 1 THEN convert(varchar(25), convert(float(1),(convert(float(1),target))*.98))  
      WHEN d.Spec_Precision = 2 THEN convert(varchar(25), convert(float(2),(convert(float(2),target))*.98))  
      WHEN d.Spec_Precision = 3 THEN convert(varchar(25), convert(float(3),(convert(float(3),target))*.98))  
      ELSE convert(varchar(25), convert(float(2),(convert(float(2),target))*.98))  
     END  
  
   END,  
  URL =   
  CASE  
   WHEN d.eng_units = 'm/min' and d.Spec_Data_Type  = 'Integer' and  d.spec = 'Line Speed Target' THEN convert(varchar(25), convert(int,(convert(int,target))*.3048*1.02))  
   WHEN d.eng_units = 'm/min' and d.Spec_Data_Type = 'Float' and d.spec = 'Line Speed Target' THEN CASE  
      WHEN d.Spec_Precision = 1 THEN convert(varchar(25), convert(float(1),(convert(float(1),target))*.3048*1.02))  
      WHEN d.Spec_Precision = 2 THEN convert(varchar(25), convert(float(2),(convert(float(2),target))*.3048*1.02))  
      WHEN d.Spec_Precision = 3 THEN convert(varchar(25), convert(float(3),(convert(float(3),target))*.3048*1.02))  
      ELSE convert(varchar(25), convert(float(2),(convert(float(2),target))*.3048*1.02))  
     END  
   WHEN d.eng_units = 'FPM' and d.Spec_Data_Type = 'Integer' and  d.spec = 'Line Speed Target'THEN convert(varchar(25), convert(int,(convert(int,target)*1.02)))  
   WHEN d.eng_units = 'FPM' and d.Spec_Data_Type = 'Float' and d.spec = 'Line Speed Target' THEN CASE  
      WHEN d.Spec_Precision = 1 THEN convert(varchar(25), convert(float(1),(convert(float(1),target))*1.02))  
      WHEN d.Spec_Precision = 2 THEN convert(varchar(25), convert(float(2),(convert(float(2),target))*1.02))  
      WHEN d.Spec_Precision = 3 THEN convert(varchar(25), convert(float(3),(convert(float(3),target))*1.02))  
      ELSE convert(varchar(25), convert(float(2),(convert(float(2),target))*1.02))  
     END  
   WHEN d.eng_units = 'cuts/min' and d.Spec_Data_Type = 'Integer' and  d.spec = 'Line Speed Target'THEN convert(varchar(25), convert(int,(convert(int,target)*1.02)))  
   WHEN d.eng_units = 'cuts/min' and d.Spec_Data_Type = 'Float' and d.spec = 'Line Speed Target' THEN CASE  
      WHEN d.Spec_Precision = 1 THEN convert(varchar(25), convert(float(1),(convert(float(1),target))*1.02))  
      WHEN d.Spec_Precision = 2 THEN convert(varchar(25), convert(float(2),(convert(float(2),target))*1.02))  
      WHEN d.Spec_Precision = 3 THEN convert(varchar(25), convert(float(3),(convert(float(3),target))*1.02))  
      ELSE convert(varchar(25), convert(float(2),(convert(float(2),target))*1.02))  
     END  
  
   END,  
        TARGET =   
   CASE  
    WHEN d.eng_units = 'm/min' and d.Spec_Data_Type = 'Integer' THEN convert(varchar(25), convert(int,(convert(int,target))*.3048))  
    WHEN d.eng_units = 'm/min' and d.Spec_Data_Type = 'Float' THEN CASE  
       WHEN d.Spec_Precision = 1 THEN convert(varchar(25), convert(float(1),(convert(float(1),target))*.3048))  
       WHEN d.Spec_Precision = 2 THEN convert(varchar(25), convert(float(2),(convert(float(2),target))*.3048))  
       WHEN d.Spec_Precision = 3 THEN convert(varchar(25), convert(float(3),(convert(float(3),target))*.3048))  
       ELSE convert(varchar(25), convert(float(2),(convert(float(2),target))*.3048))  
      END  
    WHEN d.eng_units = 'FPM' and d.Spec_Data_Type = 'Integer' THEN convert(varchar(25), convert(int,(convert(int,target))))  
    WHEN d.eng_units = 'FPM' and d.Spec_Data_Type = 'Float' THEN CASE  
       WHEN d.Spec_Precision = 1 THEN convert(varchar(25), convert(float(1),(convert(float(1),target))))  
       WHEN d.Spec_Precision = 2 THEN convert(varchar(25), convert(float(2),(convert(float(2),target))))  
       WHEN d.Spec_Precision = 3 THEN convert(varchar(25), convert(float(3),(convert(float(3),target))))  
       ELSE  convert(varchar(25), convert(float(2),(convert(float(2),target))))  
      END  
    WHEN d.eng_units = 'cuts/min' and d.Spec_Data_Type = 'Integer' THEN convert(varchar(25), convert(int,(convert(int,target))))  
    WHEN d.eng_units = 'cuts/min' and d.Spec_Data_Type = 'Float' THEN CASE  
       WHEN d.Spec_Precision = 1 THEN convert(varchar(25), convert(float(1),(convert(float(1),target))))  
       WHEN d.Spec_Precision = 2 THEN convert(varchar(25), convert(float(2),(convert(float(2),target))))  
       WHEN d.Spec_Precision = 3 THEN convert(varchar(25), convert(float(3),(convert(float(3),target))))  
       ELSE  convert(varchar(25), convert(float(2),(convert(float(2),target))))  
      END  
   END  
  FROM @Data d  
   --WHERE spec = 'Line Speed Target'  
   
 --Get the current Ideal target to verify if the insert should happen.  
 IF @SpecDesc = 'Line Speed Ideal'  
  BEGIN  
   UPDATE d  
     SET Current_Ideal = a.target  
    FROM @Data d  
     LEFT JOIN active_specs a with(nolock) ON a.spec_id = d.spec_id and a.char_id = d.char_id and a.expiration_date is null  
  END  
    
 --Get the current Target Speed and it's LRL.  
 IF @SpecDesc = 'Line Speed Target'  
  BEGIN    
   UPDATE d  
     SET Current_Target_LRL = a.L_Reject,  
      Current_Target_URL = a.U_Reject,  
      Current_Target = a.target  
    FROM @Data d  
     LEFT JOIN active_specs a with(nolock) ON a.spec_id = d.spec_id and a.char_id = d.char_id and a.expiration_date is null  
  END  
    
  
/*  Determine what to do.      */  
  
 IF upper(@TransType) = 'AUTO_JOB'  or upper(@TransType) = 'INSERT' GOTO AddNewSpecs  
 IF upper(@TransType) = 'DELETE' GOTO RemoveSpecs  
 IF upper(@TransType) = 'UPDATE' GOTO UpdateSpecs  
  
  
AddNewSpecs:  
  
/* This section will add the New Specification.                        */  
  
  
 --If char_id in @Data is Null insert a characteristic into dbo.characteristics.  
 INSERT INTO dbo.characteristics (char_desc_local,prop_id)  
  SELECT brand,prop_id   
    FROM @data   
   WHERE char_id is null  
   
 --Update char_id.  
 UPDATE d  
   SET char_id = c.char_id  
  FROM @data d  
   JOIN dbo.characteristics c with(nolock) on c.char_desc = d.brand and c.prop_id = d.prop_id and d.char_id is null  
   
 --If NeedsTreeUpdate = 1 then create transaction to update the tree.  
 IF EXISTS(SELECT * FROM @Data WHERE NeedsTreeUpdate =1)  
  BEGIN  
   SELECT @TransDesc1 = @TransDesc +' Tree Update'  
     
     --Verify the transaction does not exist, if so exit.  
    IF EXISTS(SELECT trans_desc FROM dbo.transactions WHERE trans_desc  = @TransDesc1)   
     BEGIN  
      SELECT @success =0  
      SELECT @strMsg = 'Tree Update Transaction exists already '  
      SELECT @errmsg =  @strMsg + @errsufix  
      IF upper(@UseEmail) = 'YES'  
       BEGIN  
        IF EXISTS(SELECT * FROM dbo.email_groups_data where eg_id = @GenEMail)  
         BEGIN  
          INSERT INTO dbo.email_messages(eg_id,submitted_on,em_subject,em_content)  
           VALUES(@GenEMail,getdate(),'PARTS Speeds General Error',@errmsg)  
         END          
       END  
      GOTO PlantAppsReturn  
     END  
      
   EXEC dbo.spEM_CreateTransaction  
    @TransDesc1,  --transaction description  
    null,    --corporate transaction id  
    1,    --transaction type  
    null,    --corporate transaction description  
    @UserID,   --user  
    @TransID OUTPUT --transaction id  
      
   INSERT INTO dbo.trans_char_links(trans_id, From_Char_id, To_char_id, TransOrder)  
    SELECT @TransID, Char_id, AllBrands_CharID, 1   
     FROM @Data   
      WHERE NeedsTreeUpdate = 1  
     
   SELECT @EffectiveDate = dateadd(minute,-1,@EffDate),@ApproveDate = @EffDate  
   EXEC dbo.spEM_ApproveTrans  
    @TransID,    --trans_id  
    @UserID,    --user_id  
    @TransGrp,   --transaction group  
    null,     --deviation date  
    @ApproveDate ,  --Approved Date  
    @EffectiveDate    --Effective Date  
  END  
  
 --is product assigned to the Rate Loss Unit  
-- IF EXISTS(SELECT *   
--    FROM dbo.pu_products  pup  
--     LEFT JOIN @Data d with(nolock) on d.RL_puid = pup.pu_id  
--     LEFT JOIN dbo.products p with(nolock) on p.prod_id = pup.prod_id  
--    WHERE p.prod_code = d.brand)  
 IF EXISTS(SELECT * from @PUToP WHERE ProdId is null)  
  BEGIN  
   SELECT @TransDesc1 = @TransDesc + ' Product to Units'  
     --Verify the transaction does not exist, if so exit.  
    IF EXISTS(SELECT trans_desc FROM dbo.transactions WHERE trans_desc  = @TransDesc1)   
     BEGIN  
      SELECT @success =0  
      SELECT @strMsg = 'Product to Units Transaction exists already '  
      SELECT @errmsg =  @strMsg + @errsufix  
      IF upper(@UseEmail) = 'YES'  
       BEGIN  
        IF EXISTS(SELECT * FROM dbo.email_groups_data where eg_id = @GenEMail)  
         BEGIN  
          INSERT INTO dbo.email_messages(eg_id,submitted_on,em_subject,em_content)  
           VALUES(@GenEMail,getdate(),'PARTS Speeds General Error',@errmsg)  
         END  
       END  
      GOTO PlantAppsReturn  
     END  
      
   EXEC dbo.spEM_CreateTransaction  
    @TransDesc1,  --transaction description  
    null,    --corporate transaction id  
    1,    --transaction type  
    null,    --corporate transaction description  
    @UserID,   --user  
    @TransID OUTPUT --transaction id  
      
   INSERT INTO dbo.trans_products(trans_id,pu_id,prod_id,Is_delete)  
    SELECT @TransID,d.puid,@ProdID,0  
     FROM @PUtoP d  
     WHERE d.ProdID is null  
  
   SELECT @EffectiveDate = dateadd(minute,-1,@EffDate),@ApproveDate = @EffDate  
   EXEC dbo.spEM_ApproveTrans  
    @TransID,    --trans_id  
    @UserID,    --user_id  
    @TransGrp,   --transaction group  
    null,     --deviation date  
    @ApproveDate ,  --Approved Date  
    @EffectiveDate    --Effective Date  
  END  
 ELSE  
  BEGIN  
   GOTO CheckCharToProductUnit  
  END        
 IF EXISTS(SELECT * from @PUToP WHERE ProdId is null)  
  BEGIN  
   SELECT @TransDesc1 = @TransDesc + ' Product to Units'  
  END  
CheckCharToProductUnit:  
 --is char_id  assigned to the Rate Loss Unit product  
 IF EXISTS(SELECT *   
    FROM dbo.pu_characteristics  puc  
     LEFT JOIN @Data d  on d.RL_puid = puc.pu_id and d.prop_id = puc.prop_id and d.char_id = puc.char_id  
    WHERE puc.prod_id = @ProdID)  
  BEGIN  
   GOTO UpdateSpecs  
  END  
 ELSE  
  BEGIN  
   SELECT @TransDesc1 = @TransDesc + 'Char to Product Unit'  
     --Verify the transaction does not exist, if so exit.  
    IF EXISTS(SELECT trans_desc FROM dbo.transactions WHERE trans_desc  = @TransDesc1)   
     BEGIN  
      SELECT @success =0  
      SELECT @strMsg = 'Char to  Product Unit Transaction exists already '  
      SELECT @errmsg = @strMsg + @errsufix  
      IF upper(@UseEmail) = 'YES'  
       BEGIN     
        IF EXISTS(SELECT * FROM dbo.email_groups_data where eg_id = @GenEMail)  
         BEGIN  
          INSERT INTO dbo.email_messages(eg_id,submitted_on,em_subject,em_content)  
           VALUES(@GenEMail,getdate(),'PARTS Speeds General Error',@errmsg)  
         END  
       END  
      GOTO PlantAppsReturn  
     END  
      
   EXEC dbo.spEM_CreateTransaction  
    @TransDesc1,  --transaction description  
    null,    --corporate transaction id  
    1,    --transaction type  
    null,    --corporate transaction description  
    @UserID,   --user  
    @TransID OUTPUT --transaction id  
   
   INSERT INTO dbo.trans_characteristics(trans_id,prop_id,char_id,pu_id,prod_id)  
    SELECT @TransID,d.prop_id,d.char_id,d.Rl_puid,@ProdID  
     FROM @Data d  
     
   SELECT @EffectiveDate = dateadd(minute,-1,@EffDate),@ApproveDate = @EffDate  
   EXEC dbo.spEM_ApproveTrans  
    @TransID,    --trans_id  
    @UserID,    --user_id  
    @TransGrp,   --transaction group  
    null,     --deviation date  
    @ApproveDate ,  --Approved Date  
    @EffectiveDate    --Effective Date  
  END        
  
UpdateSpecs:  
 -- Check to see if transaction should be created.  
  
 IF @TransTable = 'CONV_IDEAL_SPEEDS'   
  BEGIN  
   IF EXISTS (SELECT *   
              FROM @Data   
      WHERE Spec = 'Line Speed Ideal'   
       AND (spec_id is not null and char_id is not null and prop_id is not null)   
       AND (Current_IDeal is null or (Current_Ideal <> target)))  
    BEGIN  
     GOTO CreateTrans  
    END  
   ELSE  
    BEGIN  
     SELECT @success = 0  
     SELECT @StrMsg = 'Line Speed Ideal same as current '  
     SELECT @errmsg =  @strMsg + @errsufix  
     IF upper(@UseEmail) = 'YES'  
      BEGIN   
       IF EXISTS(SELECT * FROM dbo.email_groups_data where eg_id = @SpecsEMail)  
        BEGIN  
         INSERT INTO dbo.email_messages(eg_id,submitted_on,em_subject,em_content)  
          VALUES(@SpecsEMail,getdate(),'PARTS Speeds Specification  Error',@errmsg)  
        END  
      END  
     GOTO PlantAppsReturn  
    END  
  END  
    
 IF EXISTS(SELECT *   
           FROM @Data   
   WHERE Spec = 'Line Speed Target'   
    AND (spec_id is not null and char_id is not null and prop_id is not null)   
--    AND (Current_Target_LRL is null or (Current_Target_LRL <> LRL))   removed on 7/20/2007  
--    AND (Current_Target_URL is null or (Current_Target_URL <> URL))   removed on 7/20/2007  
    AND (Current_Target <> target or Current_Target is null))   
  BEGIN  
   GOTO CreateTrans  
  END  
 ELSE  
  BEGIN  
   SELECT @success = 0  
   SELECT @strMsg = 'Line Speed Target same as current '  
   SELECT @errmsg =  @strMsg + @errsufix  
   IF upper(@UseEmail) = 'YES'  
    BEGIN  
     IF EXISTS(SELECT * FROM dbo.email_groups_data where eg_id = @SpecsEMail)  
      BEGIN  
       INSERT INTO dbo.email_messages(eg_id,submitted_on,em_subject,em_content)  
        VALUES(@SpecsEMail,getdate(),'PARTS Speeds Specification  Error',@errmsg)  
      END  
    END  
   GOTO PlantAppsReturn  
  END  
    
GOTO PlantAppsReturn  
  
  
/*  This section will remove the Specification.               */  
  
RemoveSpecs:  
  
 IF @SpecDesc = 'Line Speed Ideal'  
  BEGIN  
   SELECT TOP 1 @OldTarget = a.target  
    FROM @Data d  
     LEFT JOIN active_specs a with(nolock) ON a.spec_id = d.spec_id and a.char_id = d.char_id and a.expiration_date  is not null  
    ORDER BY a.effective_date desc  
   UPDATE @Data  
   SET Last_Ideal = @Oldtarget  
  END  
    
 --Get the current Target Speed and it's LRL.  
 IF @SpecDesc = 'Line Speed Target'  
  BEGIN    
   SELECT TOP 1 @OldTarget = a.target, @OldLRL = a.L_reject, @OldURL = a.U_reject  
    FROM @Data d  
     LEFT JOIN active_specs a with(nolock) ON a.spec_id = d.spec_id and a.char_id = d.char_id and a.expiration_date  is not null  
    ORDER BY a.effective_date desc  
   UPDATE @Data  
   SET Last_Target_LRL = @OldLRL,  
     Last_Target_URL = @OldURL,  
     Last_Target = @OldTarget  
  END  
    
--Create the transaction.    
CreateTrans:  
/*  
 SELECT * FROM @Data  
 SELECT @TransDesc as [transdesc]  
 SELECT @success as [success]  
 SELECT @errmsg as [errmsg]  
 select @userid as [userid]  
 select @UseEmail as [emailuser]  
 select @EffDateError as [effdateerror]  
 select @effdate as [effdate]  
 return  
*/  
 EXEC dbo.spEM_CreateTransaction  
    @TransDesc,     --transaction description  
    null,        --corporate transaction id  
    1,        --transaction type  
    null,        --corporate transaction description  
    @UserID,      --user  
    @TransID OUTPUT    --transaction id  
      
 IF upper(@TransType) = 'AUTO_JOB' OR  upper(@TransType) = 'UPDATE'  OR upper(@TransType) = 'INSERT'  
  BEGIN  
   -- Update dbo.trans_properties.  
   IF @SpecDesc = 'Line Speed Target'     
    BEGIN  
     INSERT INTO dbo.trans_properties(trans_id,spec_id,char_id,target,L_Reject,U_Reject)  
      SELECT @TransID,spec_id,char_id,target,LRL,URL    
       FROM @Data  
        WHERE Spec = 'Line Speed Target'   
         AND (spec_id is not null and char_id is not null and prop_id is not null)   
         AND (Current_Target_LRL is null or (Current_Target_LRL <> LRL))   
         AND (Current_Target_URL is null or (Current_Target_URL <> URL))   
         AND (Current_Target <> target or Current_Target is null)  
    END  
      
   IF @SpecDesc = 'Line Speed Ideal'  
    BEGIN  
     INSERT INTO dbo.trans_properties(trans_id,spec_id,char_id,target)  
      SELECT @TransID,spec_id,char_id,target   
       FROM @Data   
        WHERE Spec = 'Line Speed Ideal'   
         AND (spec_id is not null and char_id is not null and prop_id is not null)   
         AND (Current_IDeal is null or (Current_Ideal <> target))  
    END  
      
    -- Set @EffectiveDate.  
    SELECT @EffectiveDate = dateadd(minute,-1,@EffDate),@ApproveDate = @EffDate  
      
    --Approve the transaction.  
    GOTO ApproveTrans  
  END  
    
 IF UPPER(@TransType) = 'DELETE'  
  BEGIN  
   IF EXISTS (SELECT *   
              FROM @Data   
      WHERE char_id is not null)  
    BEGIN  
     IF @SpecDesc = 'Line Speed Target'     
      BEGIN  
       INSERT INTO dbo.trans_properties(trans_id,spec_id,char_id,target,L_Reject,U_Reject)  
        SELECT @TransID,spec_id,char_id,Last_Target,Last_Target_LRL,Last_Target_URL  FROM @Data   
      END  
     IF @SpecDesc = 'Line Speed Ideal'  
      BEGIN  
       INSERT INTO dbo.trans_properties(trans_id,spec_id,char_id,target)  
        SELECT @TransID,spec_id,char_id,Last_Ideal FROM @Data   
      END  
     --Set @EffectiveDate.  
     SELECT @EffectiveDate = dateadd(minute,-1,@EffDate),@ApproveDate = @EffDate  
     --Approve the transaction.  
      GOTO ApproveTrans  
    END  
   ELSE  
    BEGIN  
     SELECT @success = 0  
     SELECT @StrMsg = 'No Char_id Assigned on Delete '  
     SELECT @errmsg =  @strMsg + @errsufix  
     IF upper(@UseEmail) = 'YES'  
      BEGIN   
       IF EXISTS(SELECT * FROM dbo.email_groups_data where eg_id = @SpecsEMail)  
        BEGIN  
         INSERT INTO dbo.email_messages(eg_id,submitted_on,em_subject,em_content)  
          VALUES(@SpecsEMail,getdate(),'PARTS Speeds Specification  Error',@errmsg)  
        END  
      END  
     GOTO PlantAppsReturn  
    END  
  
  END  
  
-- Approve the transaction.  
ApproveTrans:  
  
 EXEC dbo.spEM_ApproveTrans  
    @TransID,   --trans_id  
    @UserID,   --user_id  
    @TransGrp,  --transaction group  
    null,    --deviation date  
    @ApproveDate , --Approved Date  
    @EffectiveDate   --Effective Date  
  
 SELECT @Success = 1  
 SELECT @strMSG =  'Transaction: ' + @TransDesc + ' created for '   
 SELECT @errmsg = @strMsg + @errsufix  
PlantAppsReturn:  
/* testing Code */  
/*  
 SELECT * FROM @Data  
 SELECT @TransDesc as [transdesc]  
 SELECT @success as [success]  
 SELECT @errmsg as [errmsg]  
 select @userid as [userid]  
 select @UseEmail as [emailuser]  
 select @EffDateError as [effdateerror]  
 select @effdate as [effdate]  
*/  
 IF @Success = 1   
  BEGIN  
   IF upper(@UseEmail) = 'YES'  
    BEGIN  
     IF EXISTS(SELECT * FROM dbo.email_groups_data where eg_id = @SuccessEMail)  
      BEGIN  
       INSERT INTO dbo.email_messages(eg_id,submitted_on,em_subject,em_content)  
        VALUES(@SuccessEMail,getdate(),'PARTS Speeds Import Success',@errmsg)  
      END  
    END  
                      INSERT INTO [dbo].Local_Parts_Speeds_Interface_Log(resource_id, brand_code, eff_date,   
                                                                   line_speed, trans_id, trans_table, trans_type,  
                                                                   trans_outcome, interface_comments, sql_server_messages)  
                       VALUES(@NewResourceID, @NewBrandCode, @EffDate, @NewLineSpeed, @OracleTransID, @TransTable, @TransType, 'SUCCESS', @errmsg, convert(varchar,getdate()))  
  
  END  
  
 IF @Success = 0  
  BEGIN  
   IF @EffDateError = 0  
    BEGIN  
      INSERT INTO[dbo].Local_Parts_Speeds_Interface_Log(resource_id, brand_code, eff_date, line_speed, trans_id, trans_table, trans_type,  
                                   trans_outcome, interface_comments, sql_server_messages)  
            VALUES(@NewResourceID, @NewBrandCode, @EffDate, @NewLineSpeed, @OracleTransID, @TransTable, @TransType, 'FAILURE', @errmsg, convert(varchar,getdate()))  
    END  
  END  
  

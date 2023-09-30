-------------------------------------------------------------------------------------------------  
  
/*  
Stored Procedure: dbo.spLocal_Parts_BAT_Tool  
Author:    John Yannone  
Date Created:  July 26, 2005  
  
Change Date   Who  What  
===========   ====  =====  
July 20, 2007  FGO  Placed email code in   
         changed temp table to a table variable  
         added dbo. to all database objects  
         registered in VSS  
         added with(nolock) to all database objects  
  
03-FEB-2008 Langdon Davis  
 -- Corrected table reference in comment.  
 -- Modified to correct a bug where edits in the PARTS Brand table were not getting appropriately reflected   
  in the data populated within Proficy's Product_Group_Data table.  The bug was causing Proficy to have  
  many, many incorrect product group associations because the original product group associations are never   
  deleted, just new ones added.  Fixed by adding a deletion from the Product_Group_Data table of all records   
  for the indicated product where the group is one of the 'HiLevel=' type of product groups that are populated   
  from PARTS.  
  
15-AUG-2008 Langdon Davis  
 -- On an update, added updating of Prod_Desc_Local to the UPDATE statement.  Previously only Prod_Desc_Global  
  was getting updated.  
  
19-SEP-2008 Langdon Davis  
 -- Added code to populate the new 'Finished Goods Production Properties' related specs that  
  was added for the Gen IV configuration.  
 -- Added code to populate the 'Product Billed As Pallet' spec that was added as part of the  
  Auto POC work.  
 -- Cleaned up the formatting and some typos.  
  
05-JAN-2009 Langdon Davis  
 -- Modified the setting of 'Product Billed As Pallet' spec to use stat factor >2 instead of >=2 when setting   
  the spec value to Yes.  
  
24-AUG-2009 Langdon Davis  
 -- Add MsgLangID to the setting of @errdesc to insure that it used English.  
 -- Made the update of Active_Specs robust enough to handle the existence of multiple records.  
  
08-SEP-2009 Langdon Davis  
 -- Corrected e-mail group for a success.  Was sending a success to the wraning e-mail group.  
  
*/  
  
CREATE PROCEDURE dbo.spLocal_Parts_BAT_Tool  
 @errcode     int OUTPUT,  
 @errdesc             varchar(255) OUTPUT,  
 @BrandCode         varchar(9),     -- 05710                        (Brand Code)  
 @BrandDesc         varchar(50),    -- BTY 30/1 RR WHT 64CT         (Brand Description)  
 @PaperTypeID         varchar(6),     -- BYI.  
 @PaperTypeName   varchar(50),    -- Bounty I [All]               (Proficy Group Desc equivilant)  
 @BusinessArea        varchar(4),     -- K  
 @Product             varchar(8),     -- BY  
 @Prof_FamilyDesc     varchar(50),    -- Cvtg Towel Production Family (Proficy Family Description) (old - @familydesc)  
 @Prof_PropertyDesc   varchar(50),    -- Cvtg Towel Prod Factors      (Proficy Property Description) (old - @propdesc)  
 @SizeR             varchar(35),    -- Regular  
 @TheoSheetLength     float(3),       -- 287.02                       (Theo Sheet Lenght)  
 @SheetCountTrgt      int,            -- 64                           (Sheet Count Trgt)  
 @SheetLengthTrgt     float(3),       -- 11                           (Sheet Length Trgt)  
 @StatFactor          float(3),       -- 1                            (Stat Factor)  
 @Rolls               int,            -- 1                            (iFP_ItemsPerPKG_Unit)  
 @Packs               int,            -- 30                           (iPKG_Units_Per_Ship_Unit)  
 @SheetWidthTrgt      float(3),       -- 279.4                        (Sheet Width Trgt)  
 @Bundles             int,            -- 0                   (Bundles Per Layer)  
 @Layers              int,            -- 0              (Layers Per Pallet)  
 @PostPM_PTID         varchar(50),    -- BYIR                         (Post PMKG Paper Type ID.)  
 @ProfEffDate         datetime,       -- 1/1/2002                     (Proficy effective date.)  
 @ProfProdGroupDesc   varchar(75),    -- Towel:Bounty                 (Proficy Product Group Desc)  
 @PostPaperTypeName   varchar(75),    -- Bounty I Non-Microwave  
 @CurrentCodeSection  varchar(255) OUTPUT,  
 @Archived            int  
  
AS   
  
DECLARE  
 @product_id     int,  
 @prop_id        int,  
 @char_id        int,  
 @spec_id        int,  
 @prod_fam_id    int,  
 @prod_grp_id    int,  
 @spec_desc      varchar(50),  
 @spec_tgt       varchar(25),  
 @data_type      int,  
 @message_one    varchar(400),  
 @cursor_state   int,  
 @err_id         int,  
 @eff_date       datetime,  
 @PmkgParentId   varchar(7),  
 --email additions  
  @success       int,    --this is the sucess message  
  @errmsg        varchar(255), --this is the errmsg  
  @UseEmail  varchar(25), --this is the value of Use Email Engine Yes write to Email Engine No do not write  
  @errsufix  varchar(75), --this is the standard sufix to @errmsg  
  @GenEMail  int,    --this is the General Email Error Group  
  @SuccessEMail int,    --this is the Success Email Group  
  @GenProfEMail int,    --this is the General Proficy Email Group  
  @StrMsg   varchar(100), --this is the base of the output message  
 @BilledAsPallet varchar(3),  
 @ActiveSpecCount int  
  
DECLARE @specinfo TABLE(  
 spec_desc varchar(50),  
 spec_value varchar(50),  
 type_id   int  
 )  
  
/*get the value of @UseEmail */  
 SELECT TOP 1  @UseEmail=t.result  
  FROM  dbo.tests t with(nolock)  
    JOIN dbo.variables v with(nolock) ON v.var_id = t.var_id  
  WHERE v.var_desc = 'Use Email Engine'  
  ORDER BY t.result_on desc  
  
/*set @errsufix */  
 SELECT @errsufix = ' PARTS BAT Product: ' + @BrandCode  
  
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
  
  IF EXISTS(SELECT* FROM dbo.email_groups WHERE eg_desc = 'PARTS BAT (PARTS BAT Warning)')  
   BEGIN  
    SELECT @GenEMail = eg_id FROM dbo.email_groups WHERE eg_desc = 'PARTS BAT (PARTS BAT Warning)'  
   END  
  ELSE  
   BEGIN   
    SELECT @success =0  
    SELECT @strMsg ='Email Engine for PARTS BAT Warning Group not Setup '  
    SELECT @errmsg =  @strMsg + @errsufix  
    IF EXISTS(SELECT * FROM dbo.email_groups_data where eg_id = @GenProfEMail)  
     BEGIN  
      INSERT  INTO dbo.email_messages(eg_id,submitted_on,em_subject,em_content)  
         VALUES(@GenProfEMail,getdate(),'PARTS BAT Email Group Does not Exit',@errmsg)  
     END  
    GOTO PlantAppsReturn  
   END  
  
  IF EXISTS(SELECT * FROM dbo.email_groups WHERE eg_desc = 'PARTS BAT (PARTS BAT Success)')  
   BEGIN  
    SELECT @SuccessEMail = eg_id FROM dbo.email_groups WHERE eg_desc = 'PARTS BAT (PARTS BAT Success)'  
   END  
  ELSE  
   BEGIN  
    SELECT @success =0  
    SELECT @strMSG = 'Email Engine for Success Group not Setup '  
    SELECT @errmsg = @strMsg + @errsufix  
    IF EXISTS(SELECT * FROM dbo.email_groups_data where eg_id = @GenProfEMail)  
     BEGIN  
      INSERT  INTO dbo.email_messages(eg_id,submitted_on,em_subject,em_content)  
         VALUES(@GenProfEMail,getdate(),'PARTS BAT Email Group Does not Exit',@errmsg)  
     END  
    GOTO PlantAppsReturn  
   END  
 END  
  
/***********************************************************************************/  
/* Get the specs data set-up */  
/***********************************************************************************/  
  
--If the stat factor is greater than or equal to 2, we assume that the product is a BAP product.  
 IF @StatFactor > 2  
  SELECT @BilledAsPallet = 'Yes'  
 ELSE  
  SELECT @BilledAsPallet = 'No'  
  
-- If we are working with a Napkins product, the @Rolls value goes into a different   
-- spec than it does for all other products  
 IF @businessarea <> 'N'  
  insert into @specinfo  (spec_desc,   spec_value, type_id)  
  values       ('Rolls In Pack', @Rolls,   1)       -- (PARTS FP_ItemsPerPKG_Unit)  
 ELSE  
  insert into @specinfo  (spec_desc,   spec_value, type_id)  
  values       ('Packs In Pack', @Rolls,   1)       -- (PARTS FP_ItemsPerPKG_Unit)  
  
-- Populate the remaining specs [for all products].    
 insert into @specinfo  (spec_desc,   spec_value, type_id)  
 values       ('Product Code',  @BrandCode, 1)               
   
 insert into @specinfo  (spec_desc,   spec_value,   type_id)  
 values       ('Sheet Count',  @SheetCountTrgt,  1)  
  
 insert into @specinfo  (spec_desc,   spec_value,   type_id)  
 values       ('Sheet Length',  @TheoSheetLength, 2)  
  
 insert into @specinfo  (spec_desc,   spec_value,  type_id)  
 values       ('Stat Factor',  @StatFactor,  2)  
  
 insert into @specinfo  (spec_desc,    spec_value, type_id)  
 values       ('Packs In Bundle',  @Packs,   1)      --(PARTS PKG_Units_Per_Ship_Unit)  
    
 insert into @specinfo  (spec_desc,   spec_value,   type_id)  
 values       ('Sheet Width',  @SheetWidthTrgt,  2)  
     
 insert into @specinfo  (spec_desc,     spec_value, type_id)  
 values       ('Bundles Per Layer',  @Bundles,  1)  
   
 insert into @specinfo  (spec_desc,     spec_value, type_id)  
 values       ('Layers Per Pallet',  @Layers,  1)  
  
 insert into @specinfo  (spec_desc,       spec_value,   type_id)  
 values       ('Product Billed as Pallet',  @BilledAsPallet,  62)  
  
DECLARE spec_cur CURSOR FOR  
SELECT * FROM @specinfo  
  
BEGIN tran  
  
--Initialize the error handling variables.  
SELECT @errcode = 0  
SELECT @errdesc = ''  
  
/*If we are dealing with a brand code that has an archived Paper Type we   
  need to see if it already exists in the PRODUCTS table. If it does not  
  exist then there is no need to process the brand code further since  
  Proficy doesn't need it since it is archived and no longer used.  If  
  it does exist then resume normal processing. */  
IF @Archived = 1   
  BEGIN  
      IF ( SELECT COUNT(*)  
           FROM   dbo.PRODUCTS with(nolock)  
           WHERE  prod_code = @BrandCode) > 0  
   BEGIN  
    --If a record is there grab the prod_id used for the   
            --the next lookup on the PRODUCTION_STARTS table.  
            SELECT @product_id = prod_id  
            FROM   dbo.PRODUCTS with(nolock)  
            WHERE  prod_code = @BrandCode  
  
            IF ( SELECT COUNT(*)   
                 FROM   dbo.PRODUCTION_STARTS with(nolock)  
                 WHERE  prod_id = @product_id) = 0  --If it = 0 Then it doesnt exit  
  
              BEGIN  
                 SELECT @message_one = 'Brand code with archived paper type was not processed because it does not exist in PRODUCTION_STARTS table.'  
                  GOTO ProgramExit  
                END  
   END      
      ELSE --Did not find brand code in the PRODUCTS table  
   BEGIN  
               SELECT @message_one = 'Brand code with archived paper type was not processed because it does not exist in PRODUCTS table.'  
               GOTO ProgramExit  
   END  
 END --of the 'IF Archived = 1' section.  
  
--Set the '@message_one' error msg variable.   
SELECT @message_one = 'Product Family ID.  The program failed when attempting to SELECT '+  
                      'the Product_Family_ID from PRODUCT_FAMILY where Product_Family_Desc = '+ @Prof_FamilyDesc  
  
--Get the Product_Family_ID because we need it when creating/updating the PRODUCTS record.  
   SELECT  @StrMsg = 'No Product Family exists in Proficy for '+ @Prof_FamilyDesc  
 IF NOT EXISTS( SELECT product_family_id  
                  FROM   dbo.PRODUCT_FAMILY with(nolock)  
                  WHERE  product_family_desc_global = @Prof_FamilyDesc)  
  --If the given product family does not exist, end the program and send a message back.  
  GOTO data_err  
 ELSE --The product family exists  
  SELECT @prod_fam_id = product_family_id  
      FROM   dbo.PRODUCT_FAMILY with(nolock)  
      WHERE  product_family_desc_global = @Prof_FamilyDesc  
  
IF NOT EXISTS( SELECT *  
               FROM dbo.PRODUCTS with(nolock)  
               WHERE prod_code = @BrandCode)  
 BEGIN --Create new product...  
  SELECT @CurrentCodeSection = 'Inserting into PRODUCTS Table.'            
  INSERT INTO dbo.PRODUCTS ( product_family_id,   
            prod_desc_global,   
            prod_desc_local,   
            prod_code)  
           VALUES     ( @prod_fam_id,   
            @BrandDesc,  
            @BrandDesc,   
            @BrandCode)  
          
  SELECT @err_id = @@error  
  IF @err_id <> 0 GOTO Error_Handle  
 END  
ELSE --Update existing product...  
 BEGIN  
  SELECT @CurrentCodeSection = 'Updating Brand Code in PRODUCTS Table'  
  UPDATE dbo.PRODUCTS    
  SET    prod_desc_global  = @BrandDesc,  
     prod_desc_local   = @BrandDesc,  
           product_family_id  = @prod_fam_id  
  WHERE  prod_code = @BrandCode  
  
      SELECT @err_id = @@error  
      IF @err_id <> 0 GOTO Error_Handle  
 END  
  
SELECT @product_id = prod_id  
FROM   dbo.PRODUCTS with(nolock)  
WHERE  prod_code = @BrandCode  
  
/* In order to insure that the Product Group Data for the brand codes stays current as edits are made  
 in the brand table, simply delete any current product group associations for all "HiLevel=" groups  
 for this product.  The code in this sp will then create/recrate them based on the latest information   
   passed in with the parameters.  */  
DELETE FROM dbo.Product_Group_Data   
WHERE PGD_Id IN (SELECT PGD_ID  FROM Product_Group_Data pgd WITH (NOLOCK)  
           JOIN Product_Groups pg WITH (NOLOCK) ON pg.Product_Grp_Id = pgd.Product_Grp_Id   
           WHERE pgd.Prod_Id = @product_id  
           AND pg.External_Link LIKE 'HiLevel=%')  
  
/*****************************************************************************************/  
/* CREATE/UPDATE HILEVEL=1 GROUP: Concatenation of PARTS Business Area and PARTS Product */  
/*****************************************************************************************/  
IF NOT EXISTS( SELECT *  
               FROM dbo.PRODUCT_GROUPS with(nolock)  
               WHERE product_grp_desc_global = @ProfProdGroupDesc)   
 BEGIN   
  SELECT @CurrentCodeSection = 'HiLevel=1 insert into PRODUCT_GROUPS'  
  INSERT  INTO dbo.PRODUCT_GROUPS ( product_grp_desc_global,   
              product_grp_desc_local,   
              external_link)  
         VALUES (       @ProfProdGroupDesc,   
              @ProfProdGroupDesc,   
              'HiLevel=1;')    
               
  SELECT @err_id = @@error  
      IF @err_id <> 0 GOTO Error_Handle  
                  
      /*Now that the HiLevel=1 Product Group exists,  
        grab the prod_group_id necessary to see if the  
        the corresponding record exists in the PRODUCTS_GROUP_DATA table. */  
  SELECT @prod_grp_id = Product_Grp_Id  
      FROM dbo.PRODUCT_GROUPS with(nolock)  
      WHERE product_grp_desc_global = @ProfProdGroupDesc  
    
 END  
ELSE --If the group does exist already, then grab the Product_Grp_Id so we can use it to  
     -- perform a lookup in the Product_Group_Data table.  
 BEGIN          
  SELECT @CurrentCodeSection = 'HiLevel=1: Selecting @prod_grp_id from PRODUCT_GROUPS'  
    
  SELECT @prod_grp_id = Product_Grp_Id  
      FROM dbo.PRODUCT_GROUPS with(nolock)  
      WHERE product_grp_desc_global = @ProfProdGroupDesc  
 END  
  
--Populate the Product_Group_Data table for this HiLevel=1 group memebership  
IF NOT EXISTS( SELECT *  
               FROM  dbo.PRODUCT_GROUP_DATA with(nolock)  
               WHERE product_grp_id = @prod_grp_id  
               AND   prod_id        = @product_id)  
 BEGIN --It does not so we need to add the record.  
  SELECT @CurrentCodeSection = 'HiLevel=1 insert into PRODUCT_GROUP_DATA table'  
   
  INSERT  INTO dbo.PRODUCT_GROUP_DATA ( product_grp_id,   
               prod_id)  
     VALUES         ( @prod_grp_id,   
               @product_id)  
  
  SELECT @err_id = @@error  
  IF @err_id <> 0 GOTO Error_Handle  
 END  
  
/***********************************************************************************/  
/* CREATE/UPDATE HILEVEL=2 GROUP: PARTS Papermaking Paper Type name                */  
/***********************************************************************************/  
IF NOT EXISTS( SELECT *  
               FROM dbo.PRODUCT_GROUPS with(nolock)  
               WHERE product_grp_desc_global = @PaperTypeName)    
 BEGIN  
  SELECT @CurrentCodeSection = 'HiLevel=2 Pmkg Paper Type insert into PRODUCT_GROUPS table'  
              
  INSERT  INTO dbo.PRODUCT_GROUPS ( product_grp_desc_global,   
              product_grp_desc_local,   
              external_link)  
        VALUES      ( @PaperTypeName,   
              @PaperTypeName,   
              'HiLevel=2;'+'LinkId='+@PaperTypeID+';')   
             
  SELECT @err_id = @@error  
      IF @err_id <> 0 GOTO Error_Handle  
 END  
ELSE  
 BEGIN  
  SELECT @CurrentCodeSection = 'HiLevel=2 Pmkg Paper Type update of PRODUCT_GROUPS table'  
    
  UPDATE dbo.PRODUCT_GROUPS  
      SET external_link = 'HiLevel=2;'+'LinkId='+@PaperTypeID+';'   
      WHERE product_grp_desc_global = @PaperTypeName  
 END  
  
/* Now that the HiLevel=2 Pmkg Paper Type Product Group exists,  
   grab the prod_group_id necessary to see if the  
   the corresponding record exists in the PRODUCTS_GROUP_DATA table. */  
SELECT @prod_grp_id = product_grp_id  
FROM   dbo.PRODUCT_GROUPS with(nolock)  
WHERE  product_grp_desc_global = @PaperTypeName     
  
--Populate the Product_Group_Data table for this HiLevel=2 Pmkg Paper Type group memebership  
IF NOT EXISTS( SELECT *  
               FROM  dbo.PRODUCT_GROUP_DATA with(nolock)  
               WHERE product_grp_id = @prod_grp_id  
               AND   prod_id        = @product_id)  
 BEGIN  
  SELECT @CurrentCodeSection = 'HiLevel=2 Pmkg Paper Type insert into PRODUCT_GROUP_DATA table'  
  
  INSERT  INTO dbo.PRODUCT_GROUP_DATA ( product_grp_id,   
               prod_id)  
     VALUES        ( @prod_grp_id, @product_id)  
  
  SELECT @err_id = @@error  
  IF @err_id <> 0 GOTO Error_Handle  
 END  
  
  
/***********************************************************************************/  
/* CREATE/UPDATE HILEVEL=2 GROUP: PARTS Post Papermaking Paper Type name           */  
/***********************************************************************************/  
  
/* If the Papermaking and POST Papermaking Paper Type ID's are not equal then we have to  
   create an additional group representing the Post Papermaking Paper Type name. */  
IF @PaperTypeID <> @PostPM_PTID  
 BEGIN  
  --Get the Pmkg Parent Id.    
  SELECT @PmkgParentId = ( SELECT Product_Grp_Id   
                                 FROM dbo.Product_Groups  with(nolock)  
                                 WHERE Product_Grp_Desc_global = @PaperTypeName)    
  
  IF NOT EXISTS( SELECT *  
                     FROM dbo.PRODUCT_GROUPS with(nolock)  
                     WHERE product_grp_desc_global = @PostPaperTypeName)    
   BEGIN  
    SELECT @CurrentCodeSection = 'HiLevel=2 Post Pmkg Paper Type insert into PRODUCT_GROUP_DATA table'  
              
    INSERT  INTO dbo.PRODUCT_GROUPS ( product_grp_desc_global,   
                product_grp_desc_local,   
                external_link)  
                   VALUES      ( @PostPaperTypeName,   
                @PostPaperTypeName,   
                'HiLevel=2;LinkId='+@PostPM_PTID+';PmkgParentID='+@PmkgParentId+';')   
                        
    SELECT @err_id = @@error  
            IF @err_id <> 0 GOTO Error_Handle  
   END       
  ELSE  
   BEGIN  
    SELECT @CurrentCodeSection = 'HiLevel=2 Post Pmkg Paper Type update of PRODUCT_GROUPS table'  
  
            UPDATE dbo.PRODUCT_GROUPS  
            SET external_link = 'HiLevel=2;LinkId='+@PostPM_PTID+';PmkgParentID='+@PmkgParentId+';'     
            WHERE product_grp_desc_global = @PostPaperTypeName  
         END  
   
  /* Now that the HiLevel=2 Post Pmkg Product Group has been created or updated,  
         grab the prod_group_id necessary to see if the  
         the corresponding record exists in the PRODUCTS_GROUP_DATA table. */  
  SELECT @prod_grp_id = product_grp_id  
  FROM   dbo.PRODUCT_GROUPS with(nolock)  
  WHERE  product_grp_desc_global = @PostPaperTypeName     
  
  --Populate the Product_Group_Data table for this HiLevel=2 Post Pmkg Paper Type group memebership  
  IF NOT EXISTS( SELECT *  
                     FROM  dbo.PRODUCT_GROUP_DATA with(nolock)  
                     WHERE product_grp_id = @prod_grp_id  
                     AND   prod_id        = @product_id)  
   BEGIN  
    SELECT @CurrentCodeSection = 'HiLevel=2 POST-PTID Name SUB INSERT into PRODUCT_GROUP_DATA table'  
  
          INSERT  INTO dbo.PRODUCT_GROUP_DATA ( product_grp_id,   
                 prod_id)  
       VALUES                ( @prod_grp_id,   
                 @product_id)  
                   
            SELECT @err_id = @@error  
            IF @err_id <> 0 GOTO Error_Handle  
   END  
  
 END --of '@PaperTypeID <> @PostPM_PTID'  
  
--Reset the @message_one error msg value.  
SELECT @message_one = 'Product Properties. The program failed when it was unable to SELECT the prop_id ' +  
                      ' from PRODUCT_PROPERTIES where prop_desc = ' + @Prof_PropertyDesc  
  
/* See if a record exists based on the propdesc passed in.  This should never fail  
   (except for maybe a typo), so if the lookup fails, we need to end the program run   
 and send the data error msg back to the client. */    
 IF NOT EXISTS ( SELECT *  
                 FROM  dbo.PRODUCT_PROPERTIES with(nolock)  
                 WHERE prop_desc_global = @Prof_PropertyDesc)  
  BEGIN  
   SELECT  @StrMsg = 'No Product Property exists in Proficy for '+ @Prof_PropertyDesc  
   GOTO Data_Err  
  END  
 ELSE  
      BEGIN  
        SELECT @prop_id = prop_id  
        FROM   dbo.PRODUCT_PROPERTIES with(nolock)  
        WHERE  prop_desc_global = @Prof_PropertyDesc  
      END  
  
IF NOT EXISTS(SELECT *  
              FROM  dbo.CHARACTERISTICS with(nolock)  
              WHERE prop_id = @prop_id  
              AND   char_desc_global = @BrandCode)  
 BEGIN --Create new characteristic...  
  SELECT @CurrentCodeSection = 'Inserting into CHARACTERISTICS'  
    
  INSERT  INTO dbo.characteristics ( prop_id,   
              char_desc_global,   
              char_desc_local)  
     VALUES       ( @prop_id,   
              @BrandCode,   
              @BrandCode)  
  
  SELECT @err_id = @@error  
  IF @err_id <> 0 GOTO Error_Handle  
  
  SELECT @char_id = char_id  
  FROM   dbo.CHARACTERISTICS with(nolock)  
  WHERE  prop_id = @prop_id  
  AND    char_desc_global = @BrandCode          
 END  
ELSE --If a record exists then grab the char_id.  
 BEGIN  
  SELECT @char_id = char_id  
      FROM   dbo.CHARACTERISTICS with(nolock)  
  WHERE  prop_id = @prop_id  
  AND    char_desc_global = @BrandCode  
 END  
  
--Populate the specifications based on the cursor data.  
OPEN spec_cur  
FETCH NEXT FROM spec_cur  
INTO @spec_desc, @spec_tgt, @data_type  
  
--Set cursor state = 1 to signify that it has been opened.  
SELECT @cursor_state = 1  
  
--A Fetch status of zero means we are not at the end of the cursor  
--i.e. there's a record in the cursor  
WHILE @@FETCH_STATUS = 0  
 BEGIN  
  --Reset the @message_one error msg variable.  
  SELECT @message_one = 'Specifications. The program failed when attempting to select a spec_id from SPECIFICATIONS ' +  
                            'where prop_id =  ' + cast(@prop_id as varchar) + '  AND spec_desc = ' + @spec_desc + '.'+  
                            ' The current spec_tgt cursor value is = ' + @spec_tgt + ' with a data type of ' +  
                             cast(@data_type as varchar)  
  
  --Look for an existing record.  
      IF NOT EXISTS( SELECT *  
                     FROM dbo.SPECIFICATIONS with(nolock)  
                     WHERE prop_id = @prop_id  
                     AND spec_desc_global = @spec_desc)  
  
   BEGIN  
    IF @spec_desc = 'Product Billed As Pallet'  --This spec does not exist at all sites  
                    --so failure to find it is not an error.  
     GOTO skip_spec  
    ELSE  
     BEGIN  
      SELECT  @StrMsg = 'No Specification exists in Proficy for prop_id =  '+ cast(@prop_id as varchar) +   
            '  AND spec_desc = ' + @spec_desc  
              GOTO Data_Err  
           END  
   END  
  ELSE --A record does exists so grab the spec_id.  
   BEGIN  
    SELECT @spec_id = spec_id  
            FROM   dbo.SPECIFICATIONS with(nolock)  
            WHERE  prop_id = @prop_id  
            AND    spec_desc_global = @spec_desc  
         END  
  
  --If the spec value passed in equals zero then DO NOT create an entry for  
    --that value in the Active Specs table.  
    IF @spec_tgt = '0' GOTO skip_spec  
  
  --Look to see if data already exists in ACTIVE_SPECS table.  
  IF NOT EXISTS( SELECT *  
                     FROM  dbo.ACTIVE_SPECS with(nolock)  
                     WHERE spec_id = @spec_id  
                     AND   char_id = @char_id  
                     AND   expiration_date is null)  
  
   --Use PROFICY_EFF_DATE coming over from PARTS regardless of this is an update or creation. */  
    BEGIN  
    SELECT @CurrentCodeSection = 'Inserting into ACTIVE_SPECS'  
  
           INSERT  INTO dbo.ACTIVE_SPECS ( effective_date,   
               spec_id,   
               char_id,   
               is_defined,   
               target)  
       VALUES      ( @ProfEffDate,   
               @spec_id,   
               @char_id,   
               16,   
               @spec_tgt)    
                     
    SELECT @err_id = @@error  
            IF @err_id <> 0 GOTO Error_Handle  
   END  
  ELSE   
   BEGIN  
    SELECT @CurrentCodeSection = 'Updating ACTIVE_SPECS'  
  
          SELECT @ActiveSpecCount = COUNT(AS_Id) from dbo.ACTIVE_SPECS  
    WHERE  spec_id = @spec_id  
          AND    char_id = @char_id  
            
    IF @ActiveSpecCount =1  
     BEGIN  
      UPDATE dbo.ACTIVE_SPECS  
            SET    target = @spec_tgt,  
                     effective_date = @ProfEffDate  
            WHERE  spec_id = @spec_id  
            AND    char_id = @char_id  
            AND    expiration_date IS NULL   
     END  
    ELSE  
     BEGIN  
      DELETE FROM dbo.ACTIVE_SPECS  
      WHERE  spec_id = @spec_id  
            AND    char_id = @char_id  
      AND   expiration_date IS NOT NULL   
  
      UPDATE dbo.ACTIVE_SPECS  
            SET    target = @spec_tgt,  
                     effective_date = @ProfEffDate  
            WHERE  spec_id = @spec_id  
            AND    char_id = @char_id  
            AND    expiration_date IS NULL       
     END   
  
            SELECT @err_id = @@error  
            IF @err_id <> 0 GOTO Error_Handle  
   END  
  
  --This is a Label.  
  skip_spec:  
  
  FETCH next FROM spec_cur  
  INTO @spec_desc, @spec_tgt, @data_type  
  
 END --Error is here  
  
CLOSE spec_cur  
  
/****************************************************************************************/  
/* Populate the data for the 'Finished Goods Production Factors' poperty if it          */  
/* exists.  This property was added to handle the Gen IV lines' flexibility to run      */  
/* either Tissue or Towel products.  It is not present on all sites.  Where it is       */  
/* present, we need to do the same thing we just did above for the property description */  
/* that was passed in as a parameter.                                                   */  
/****************************************************************************************/  
  
IF EXISTS ( SELECT *  
            FROM  dbo.PRODUCT_PROPERTIES with(nolock)  
            WHERE prop_desc_global = 'Finished Goods Production Factors')  
 BEGIN  
  SELECT @prop_id = prop_id  
      FROM   dbo.PRODUCT_PROPERTIES with(nolock)  
      WHERE  prop_desc_global = 'Finished Goods Production Factors'  
  
  IF NOT EXISTS( SELECT *  
                 FROM  dbo.CHARACTERISTICS with(nolock)  
                 WHERE prop_id = @prop_id  
                 AND   char_desc_global = @BrandCode)  
   BEGIN --Create new characteristic...  
    SELECT @CurrentCodeSection = 'Inserting into CHARACTERISTICS'  
    
    INSERT  INTO dbo.characteristics ( prop_id,   
                char_desc_global,   
                char_desc_local)  
       VALUES       ( @prop_id,   
                @BrandCode,   
                @BrandCode)  
  
    SELECT @err_id = @@error  
    IF @err_id <> 0 GOTO Error_Handle  
  
    SELECT @char_id = char_id  
    FROM   dbo.CHARACTERISTICS with(nolock)  
    WHERE  prop_id = @prop_id  
    AND    char_desc_global = @BrandCode          
   END  
  ELSE --If a record exists then grab the char_id.  
   BEGIN  
    SELECT @char_id = char_id  
        FROM   dbo.CHARACTERISTICS with(nolock)  
    WHERE  prop_id = @prop_id  
    AND    char_desc_global = @BrandCode  
   END  
  
  --Populate the specifications based on the cursor data.  
  OPEN spec_cur  
  FETCH NEXT FROM spec_cur  
  INTO @spec_desc, @spec_tgt, @data_type  
  
  --Set cursor state = 1 to signify that it has been opened.  
  SELECT @cursor_state = 1  
  
  --A Fetch status of zero means we are not at the end of the cursor  
  --i.e. there's a record in the cursor  
  WHILE @@FETCH_STATUS = 0  
   BEGIN  
    --Reset the @message_one error msg variable.  
    SELECT @message_one = 'Specifications. The program failed when attempting to select a spec_id from SPECIFICATIONS ' +  
                              'where prop_id =  ' + cast(@prop_id as varchar) + '  AND spec_desc = ' + @spec_desc + '.'+  
                              ' The current spec_tgt cursor value is = ' + @spec_tgt + ' with a data type of ' +  
                               cast(@data_type as varchar)  
  
    --Look for an existing record.  
        IF NOT EXISTS( SELECT *  
                       FROM dbo.SPECIFICATIONS with(nolock)  
                        WHERE prop_id = @prop_id  
                       AND spec_desc_global = @spec_desc)  
  
     BEGIN  
      IF @spec_desc = 'Product Billed As Pallet'  --This spec does not exist at all sites  
                       --so failure to find it is not an error.  
       GOTO skip_spec_FG  
      ELSE  
       BEGIN  
        SELECT  @StrMsg = 'No Specification exists in Proficy for prop_id =  '+ cast(@prop_id as varchar) +   
              '  AND spec_desc = ' + @spec_desc  
                GOTO Data_Err  
             END  
     END  
    ELSE --A record does exists so grab the spec_id.  
     BEGIN  
      SELECT @spec_id = spec_id  
              FROM   dbo.SPECIFICATIONS with(nolock)  
              WHERE  prop_id = @prop_id  
              AND    spec_desc_global = @spec_desc  
           END  
  
    --If the spec value passed in equals zero then DO NOT create an entry for  
      --that value in the Active Specs table.  
      IF @spec_tgt = '0' GOTO skip_spec_FG  
  
    --Look to see if data already exists in ACTIVE_SPECS table.  
    IF NOT EXISTS( SELECT *  
                       FROM  dbo.ACTIVE_SPECS with(nolock)  
                       WHERE spec_id = @spec_id  
                        AND   char_id = @char_id  
                       AND   expiration_date is null)  
  
     --Use PROFICY_EFF_DATE coming over from PARTS regardless of this is an update or creation.   
      BEGIN  
      SELECT @CurrentCodeSection = 'Inserting into ACTIVE_SPECS'  
  
             INSERT  INTO dbo.ACTIVE_SPECS ( effective_date,   
                 spec_id,   
                 char_id,   
                 is_defined,   
                 target)  
                 VALUES      ( @ProfEffDate,   
                 @spec_id,   
                 @char_id,   
                 16,   
                 @spec_tgt)    
                     
      SELECT @err_id = @@error  
              IF @err_id <> 0 GOTO Error_Handle  
     END  
    ELSE  --Error is here  
     BEGIN  
      SELECT @CurrentCodeSection = 'Updating ACTIVE_SPECS'  
  
            SELECT @ActiveSpecCount = COUNT(AS_Id) from dbo.ACTIVE_SPECS  
      WHERE  spec_id = @spec_id  
            AND    char_id = @char_id  
            
      IF @ActiveSpecCount =1  
       BEGIN  
        UPDATE dbo.ACTIVE_SPECS  
              SET    target = @spec_tgt,  
                        effective_date = @ProfEffDate  
              WHERE  spec_id = @spec_id  
              AND    char_id = @char_id  
              AND    expiration_date IS NULL   
       END  
      ELSE  
       BEGIN  
        DELETE FROM dbo.ACTIVE_SPECS  
        WHERE  spec_id = @spec_id  
              AND    char_id = @char_id  
        AND   expiration_date IS NOT NULL   
  
        UPDATE dbo.ACTIVE_SPECS  
              SET    target = @spec_tgt,  
                        effective_date = @ProfEffDate  
              WHERE  spec_id = @spec_id  
              AND    char_id = @char_id  
              AND    expiration_date IS NULL       
       END    
  
              SELECT @err_id = @@error  
              IF @err_id <> 0 GOTO Error_Handle  
     END  
  
    --This is a Label.  
    skip_spec_FG:  
  
    FETCH next FROM spec_cur  
    INTO @spec_desc, @spec_tgt, @data_type  
  
   END  --Error is here  
    
  CLOSE spec_cur  
   
 END  --to BEGIN for if 'Finished Goods Production Factors exists.  
  
DEALLOCATE  spec_cur  
  
COMMIT tran  
  
--If program reached here we have success!  
SELECT @CurrentCodeSection = 'SP COMPLETED NORMALLY!'  
  
IF upper(@UseEmail) = 'YES'  
 BEGIN  
  SELECT @Success = 0  
  SELECT @strMsg ='Product Add was successful'  
  SELECT @errmsg =  @StrMsg + @errsufix  
  IF EXISTS( SELECT *   
      FROM dbo.email_groups_data   
      WHERE eg_id = @SuccessEMail)  
   BEGIN  
    INSERT  INTO dbo.email_messages ( eg_id,  
                submitted_on,  
                em_subject,  
                em_content)  
       VALUES      ( @SuccessEMail,  
                getdate(),  
                'PARTS BAT:  ' + @strMsg ,  
                @errmsg)  
   END  
 END  
--Return to end the program so it will not go into the following section accidentally.   
RETURN  
  
ProgramExit:  
--Used for exiting program when dealing with archived Paper Types  
SELECT @errdesc = @message_one  
SELECT @errcode = 2  
SELECT @CurrentCodeSection = 'Brand code ' + @BrandCode + 'was not processed because it has an archived Paper Type'  
ROLLBACK tran  
IF @cursor_state = 1  
 BEGIN  
    CLOSE spec_cur  
      DEALLOCATE spec_cur  
   END  
  
IF upper(@UseEmail) = 'YES'  
 BEGIN  
  SELECT @Success = 0  
  SELECT @strMsg =@CurrentCodeSection  
  SELECT @errmsg =  @StrMsg + @errsufix  
  IF EXISTS( SELECT *   
      FROM dbo.email_groups_data   
      WHERE eg_id = @GenEMail)  
   BEGIN  
    INSERT  INTO dbo.email_messages ( eg_id,  
                submitted_on,  
                em_subject,  
                em_content)  
       VALUES      ( @GenEMail,  
                getdate(),  
                'PARTS BAT:  ' + @strMsg ,  
                @errmsg)  
   END  
 END  
RETURN  
  
/*Sends an error message back to the calling program if the  
  stored procedure encounters a data error.*/  
Data_Err:  
SELECT @errdesc = 'Missing data for ' + @message_one  
SELECT @errcode = 1  
SELECT @CurrentCodeSection = 'Data Error Occured!'  
ROLLBACK tran  
IF @cursor_state = 1  
 BEGIN  
    CLOSE spec_cur  
      DEALLOCATE spec_cur  
   END  
  
IF upper(@UseEmail) = 'YES'  
 BEGIN  
  SELECT @Success = 0  
  SELECT @errmsg =  @StrMsg + @errsufix  
  IF EXISTS( SELECT *   
      FROM dbo.email_groups_data   
      WHERE eg_id = @GenEMail)  
   BEGIN  
    INSERT  INTO dbo.email_messages ( eg_id,  
                submitted_on,  
                em_subject,  
                em_content)  
       VALUES      ( @GenEMail,  
                getdate(),  
                'PARTS BAT:  ' + @strMsg ,  
                @errmsg)  
   END  
 END  
RETURN  
  
--System error handler.  
Error_Handle:  
SELECT @errcode = @err_id  
  
SELECT @errdesc = description     
FROM   master.dbo.sysmessages  
WHERE  error = @err_id   
AND  msglangid = 1033  
  
SELECT @CurrentCodeSection = 'System Error: '+@CurrentCodeSection   
ROLLBACK tran  
IF @cursor_state = 1  
 BEGIN  
    CLOSE spec_cur  
      DEALLOCATE spec_cur  
   END  
  
IF upper(@UseEmail) = 'YES'  
 BEGIN  
  SELECT @Success = 0  
  SELECT @strMsg ='Error in ' +@CurrentCodeSection  
  SELECT @errmsg =  @StrMsg + @errsufix  
  IF EXISTS( SELECT *   
      FROM dbo.email_groups_data   
      WHERE eg_id = @GenEMail)  
   BEGIN  
    INSERT  INTO dbo.email_messages( eg_id,  
                submitted_on,  
                em_subject,  
                em_content)  
       VALUES       ( @GenEMail,  
                getdate(),  
                'PARTS BAT:  ' + @strMsg ,  
                @errmsg)  
   END  
 END  
  
RETURN  
  
PlantAppsReturn:  

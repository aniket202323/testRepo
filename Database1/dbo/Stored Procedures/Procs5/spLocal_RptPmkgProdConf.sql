 /*  
Stored Procedure: spLocal_GetPOCSummaryData  
Author:   Matt Wells (MSI)  
Date Created:  05/30/02  
  
Description:  
=========  
This procedure provides Process Order Confirmation data for a given Line and Time Period.  
  
  
INPUTS:  Start Time  
  End Time  
  Production Line Name (without the TT prefix)  
  Product ID for Report 0:  Returns summary data grouped by Product for all Products run in time period specified  
     Product ID: Returns summary data for this Product ID in time period specified  
  
CALLED BY:  RptPmkgProdConf.xlt (Excel/VBA Template)  
  
CALLS: None  
  
Revision Change Date Who What  
======== =========== ==== =====  
0.0  5/30/02  MKW Original Creation  
1.0  6/13/02  CE Corrected Reel Tonnes calculations  
1.1  6/17/02  CE Added Fire and Hold Tones to Reel Tonnes calc  
1.2  6/20/02  CE Changed to Usage variables instead of Mass Flow variables; fixed logic to insert @Last_GCAS into #Summary_Data table  
1.3  11/08/02  KH Modified Good Tons Sum to include Consumed and Shipped Tons  
  
1.4  04/21/04 JSJ - Changed file name to spLocal_RptPmkgProdConf.  
     - Changed all REAL data types to FLOAT.  
     - Added code to assign permissions to the stored procedure when created.  
     - Added code to drop the sp, if it exists, before creating it again.  
     - Removed unused code.  
     - Added parameter checks.  
     - Added the #ErrMsg table.  
     - Added flow control around the result sets.  
     - Added the new parameter @UserName.  
     - Removed the use of conversion variables.  
     - Added variables, #temp table fields and code for pulling eng_units.  
     - Added a check on the count or records to the result set, along with   
       the variables related to the check.  
     - Added the variables and code for language translation.  
     - Removed unused fields from #Summary_Data.  If additional entries need to   
       be added to this table in the future, they should be added just before   
       the _Units fields.  Any addition fields for Units should be added to the end.  
     - Added Recycle_Fiber and related Units field to #Summary_Data, along with   
       relevant code.  
  
1.5  12/16/04 JSJ - removed some unused code.  
     - brought this report up to date with Checklist 110804.  
     - removed the temp table #Production_Runs, since it doesn't appear to be used.  
1.6  03-OCT-2006  Langdon Davis  
   Modified the @username parameter check to default to 'Webguest' if NULL or blank.  
  
*/  
  
CREATE PROCEDURE dbo.spLocal_RptPmkgProdConf  
--Declare  
  
@Report_Start_Time datetime,  
@Report_End_Time datetime,  
@Line_Name   varchar(50),  
@Report_Prod_Id  int,  
@UserName  varchar(30)  
  
AS  
  
  
/* Testing...   
  
Select  @Line_Name   = 'AY1A',  --'MP8M' ,  
 @Report_Start_Time  = '2004-12-13 00:00:00',  
 @Report_End_Time    = '2004-12-14 00:00:00',  
  @Report_Prod_Id  = Null, --1013,  
 @UserName  = 'ComXClient'  
  
  
*/  
  
/************************************************************************************************  
*                                                                                               *  
*                                 Global execution switches                                     *  
*                                                                                               *  
************************************************************************************************/  
SET NOCOUNT ON  
SET ANSI_WARNINGS OFF  
  
  
/************************************************************************************************  
*                                                                                               *  
*                               Create Temporary Tables      *  
*                                                                                               *  
************************************************************************************************/  
--declare @Production_Runs table  
--(  
-- Start_Id int Primary Key,  
-- Prod_Id  int Not Null,  
-- Prod_Desc varchar(50),  
-- Start_Time datetime Not Null,  
-- End_Time datetime Not Null  
--)  
  
-- Note if fields need to be added, put them just before the _Units fields that track eng_units.  
-- New fields that track the eng_units should be added to the end.  
-- The template uses field numbers to reference returned data, and will need to be updated when this table   
-- is modified.  
  
Create Table #Summary_Data (  
 Plant    varchar(25),  
 Storage_Location  varchar(25),  
 Product    varchar(50),  
 GCAS    varchar(25),  
 Reel_Tons   decimal(15,2),  
 Furnish    decimal(15,2),  
 Third_Furnish   decimal(15,2),  
 Absorb_Aid_Towel  decimal(15,2),  
 Cat_Promoter   decimal(15,2),  
 Chem_1    decimal(15,2),  
 Chem_2    decimal(15,2),  
 CTMP    decimal(15,2),  
 Dry_Strength_Tissue  decimal(15,2),  
 Dry_Strength_Towel  decimal(15,2),  
 Dye_1    decimal(15,2),  
 Dye_2    decimal(15,2),  
 Fiber_1    decimal(15,2),  
 Fiber_2    decimal(15,2),  
 Long_Fiber   decimal(15,2),  
 Product_Broke   decimal(15,2),  
 Short_Fiber   decimal(15,2),  
 Softener_Tissue   decimal(15,2),  
 Softener_Towel   decimal(15,2),  
 Wet_Strength_Tissue  decimal(15,2),  
 Wet_Strength_Towel  decimal(15,2),  
 Aloe_E_Additive   decimal(15,2),  
 Softener_Facial   decimal(15,2),  
 Wet_Strength_Facial  decimal(15,2),  
 Dry_Strength_Facial  decimal(15,2),  
 Recycle_Fiber   decimal(15,2),   
 Third_Furnish_Units   varchar(15),  
 Absorb_Aid_Towel_Units  varchar(15),  
 Cat_Promoter_Units  varchar(15),  
 Chem1_Units   varchar(15),  
 Chem2_Units   varchar(15),  
 CTMP_Units   varchar(15),  
 Dry_Strength_Facial_Units varchar(15),  
 Dry_Strength_Tissue_Units varchar(15),  
 Dry_Strength_Towel_Units varchar(15),  
 Dye1_Units   varchar(15),  
 Dye2_Units   varchar(15),  
 Fiber1_Units   varchar(15),  
 Fiber2_Units   varchar(15),  
 Long_Fiber_Units  varchar(15),  
 Product_Broke_Units  varchar(15),  
 Short_Fiber_Units  varchar(15),  
 Softener_Tissue_Units  varchar(15),  
 Softener_Towel_Units  varchar(15),  
 Wet_Strength_Tissue_Units varchar(15),  
 Wet_Strength_Towel_Units varchar(15),  
 Aloe_E_Additive_Units  varchar(15),  
 Softener_Facial_Units  varchar(15),  
 Wet_Strength_Facial_Units varchar(15),  
 Recycle_Fiber_Units  varchar(15)  
)  
  
  
-------------------------------------------------------------------------------  
-- Initialization  
-------------------------------------------------------------------------------  
DECLARE @ErrorMessages TABLE ( ErrMsg varchar(255) )  
  
  
-------------------------------------------------------------------------------  
-- Check Input Parameters.  
-------------------------------------------------------------------------------  
IF 'TT ' + ltrim(rtrim(@Line_Name)) not in (select pl_desc from prod_lines)  
 BEGIN  
 INSERT @ErrorMessages (ErrMsg)  
  VALUES ('@Line_Name is not valid.')  
 GOTO ReturnResultSets  
 END  
IF IsDate(@Report_Start_Time) <> 1  
 BEGIN  
 INSERT @ErrorMessages (ErrMsg)  
  VALUES ('@Report_Start_Time is not a Date.')  
 GOTO ReturnResultSets  
 END  
IF IsDate(@Report_End_Time) <> 1  
 BEGIN  
 INSERT @ErrorMessages (ErrMsg)  
  VALUES ('@Report_End_Time is not a Date.')  
 GOTO ReturnResultSets  
 END  
IF @Report_Prod_ID not in (select pu_id from prod_units)  
 BEGIN  
 INSERT @ErrorMessages (ErrMsg)  
  VALUES ('@Report_Prod_ID is not valid.')  
 GOTO ReturnResultSets  
 END  
-- IF (SELECT count(username) FROM users WHERE username = @username) = 0  
--  BEGIN  
--  INSERT @ErrorMessages (ErrMsg)  
--   VALUES ('@UserName is not valid.')  
--  GOTO ReturnResultSets  
--  END  
IF @UserName IS NULL OR LEN(@UserName)= 0  
 BEGIN  
 Select @UserName = 'Webguest'  
 END  
  
------------------------------------------------------------------------  
-- Declare Program Variables  
-----------------------------------------------------------------------  
  
Declare @PL_Id    int,  
 @Total    float,  
 @Count    int,  
 @Production_PU_Id  int,  
 @Quality_PU_Id   int,  
 @Rolls_PU_Id   int,  
 @Sheetbreak_PU_Id  int,  
 @Materials_PU_Id  int,  
 @Reel_Time_Var_Id  int,  
 @Product_Start_Time  datetime,   @Product_End_Time  datetime,  
 @Prod_Id   int,  
 @Prod_Desc   varchar(50),  
 @Last_Prod_Id   int,  
 @Last_Prod_Desc   varchar(50),  
 @Product_Time   float,  
 @Prop_Id   int,  
 @Ratio_Spec_Id   int,  
 @GCAS_Char_Id   int,  
 @GCAS    varchar(8),  
 @Last_GCAS   varchar(8),  
 @Ratio    float,  
             --**************** Tonnage/Count Variables ***************  
 @Reel_Tons_Sum   float,  
 @Good_Tons_Var_Id  int,  
 @Consumed_Tons_Var_Id  int,  
 @Shipped_Tons_Var_Id  int,  
 @Reject_Tons_Var_Id  int,  
 @Fire_Tons_Var_Id  int,  
 @Hold_Tons_Var_Id  int,  
      --**************** Plant/Location Variables ***************  
 @Extended_Info   varchar(255),  
 @Plant    varchar(25),  
 @Plant_Flag   varchar(25),  
 @Storage_Location  varchar(25),  
 @Storage_Location_Flag  varchar(25),  
 @Flag_Start_Position  int,  
 @Flag_End_Position  int,  
 @Flag_Value_Str   varchar(255),  
             --************** Furnish Variables ***************  
 @3rd_Furnish_Var_Id  int,  
 @CTMP_Var_Id   int,  
 @Fiber_1_Var_Id   int,  
 @Fiber_2_Var_Id   int,  
 @Long_Fiber_Var_Id  int,  
 @Product_Broke_Var_Id  int,  
 @Short_Fiber_Var_Id  int,  
 @Recycle_Fiber_Var_Id  int,  
 @3rd_Furnish_Sum  float,  
 @CTMP_Sum   float,  
 @Fiber_1_Sum   float,  
 @Fiber_2_Sum   float,  
 @Long_Fiber_Sum   float,  
 @Product_Broke_Sum  float,  
 @Short_Fiber_Sum  float,  
 @Recycle_Fiber_Sum  float,  
 @Furnish_Sum   float,  
             --************** Chemical Variables ***************  
 @Absorb_Aid_Towel_Var_Id int,  
 @Aloe_E_Additive_Var_Id  int,  
 @Cat_Promoter_Var_Id  int,  
 @Chem_1_Var_Id   int,  
 @Chem_2_Var_Id   int,  
 @Dry_Strength_Facial_Var_Id int,  
 @Dry_Strength_Tissue_Var_Id int,  
 @Dry_Strength_Towel_Var_Id int,  
 @Dye_1_Var_Id   int,  
 @Dye_2_Var_Id   int,  
 @Softener_Facial_Var_Id  int,  
 @Softener_Tissue_Var_Id  int,  
 @Softener_Towel_Var_Id  int,  
 @Wet_Strength_Facial_Var_Id int,  
 @Wet_Strength_Tissue_Var_Id int,  
 @Wet_Strength_Towel_Var_Id int,  
 @Absorb_Aid_Towel_Sum  float,  
 @Aloe_E_Additive_Sum  float,  
 @Cat_Promoter_Sum  float,  
 @Chem_1_Sum   float,  
 @Chem_2_Sum   float,  
 @Dry_Strength_Facial_Sum float,  
 @Dry_Strength_Tissue_Sum float,  
 @Dry_Strength_Towel_Sum  float,  
 @Dye_1_Sum   float,  
 @Dye_2_Sum   float,  
 @Softener_Facial_Sum  float,  
 @Softener_Tissue_Sum  float,  
 @Softener_Towel_Sum  float,  
 @Wet_Strength_Facial_Sum float,  
 @Wet_Strength_Tissue_Sum float,  
 @Wet_Strength_Towel_Sum  float,  
     --************** Language and Other Variables ********  
 @LanguageId   integer,  
 @UserId    integer,  
 @LanguageParmId   integer,  
 @NoDataMsg    varchar(50),  
 @TooMuchDataMsg   varchar(50),  
 @SQL     varchar(8000),  
 --************ Unit Variables *********************  
 @Third_Furnish_Units   varchar(15),  
 @Absorb_Aid_Towel_Units  varchar(15),  
 @Cat_Promoter_Units  varchar(15),  
 @Chem1_Units   varchar(15),  
 @Chem2_Units   varchar(15),  
 @CTMP_Units   varchar(15),  
 @Dry_Strength_Facial_units varchar(15),  
 @Dry_Strength_Tissue_Units varchar(15),  
 @Dry_Strength_Towel_Units varchar(15),  
 @Dye1_Units   varchar(15),  
 @Dye2_Units   varchar(15),  
 @Fiber1_Units   varchar(15),  
 @Fiber2_Units   varchar(15),  
 @Long_Fiber_Units  varchar(15),  
 @Product_Broke_Units  varchar(15),  
 @Short_Fiber_Units  varchar(15),  
 @Recycle_Fiber_Units  varchar(15),  
 @Softener_Tissue_Units  varchar(15),  
 @Softener_Towel_Units  varchar(15),  
 @Wet_Strength_Tissue_Units varchar(15),  
 @Wet_Strength_Towel_Units varchar(15),  
 @Aloe_E_Additive_Units  varchar(15),  
 @Softener_Facial_Units  varchar(15),  
 @Wet_Strength_Facial_Units varchar(15)  
   
  
/************************************************************************************************  
*                                                                                                                               *  
*                                     Initialization                                            *  
*                               *  
************************************************************************************************/  
Select  @Plant_Flag   = 'Plant=',  
 @Storage_Location_Flag  = 'StorageLocation=',  
 @Product_Time   = Null,  
 @Reel_Tons_Sum    = Null,  
 @Furnish_Sum   = Null,  
 @3rd_Furnish_Sum   = Null,  
 @Absorb_Aid_Towel_Sum   = Null,  
 @Aloe_E_Additive_Sum   = Null,  
 @Cat_Promoter_Sum   = Null,  
 @Chem_1_Sum    = Null,  
 @Chem_2_Sum    = Null,  
 @CTMP_Sum    = Null,  
 @Dry_Strength_Facial_Sum = Null,  
 @Dry_Strength_Tissue_Sum = Null,  
 @Dry_Strength_Towel_Sum  = Null,  
 @Dye_1_Sum    = Null,  
 @Dye_2_Sum    = Null,  
 @Fiber_1_Sum    = Null,  
 @Fiber_2_Sum    = Null,  
 @Long_Fiber_Sum   = Null,  
 @Product_Broke_Sum   = Null,  
 @Short_Fiber_Sum   = Null,  
 @Recycle_Fiber_Sum  = Null,  
 @Softener_Facial_Sum  = Null,  
 @Softener_Tissue_Sum  = Null,  
 @Softener_Towel_Sum  = Null,  
 @Wet_Strength_Facial_Sum = Null,  
 @Wet_Strength_Tissue_Sum = Null,  
 @Wet_Strength_Towel_Sum  = Null,  
 @Third_Furnish_Units   = Null,  
 @Absorb_Aid_Towel_Units  = Null,  
 @Cat_Promoter_Units  = Null,  
 @Chem1_Units   = Null,  
 @Chem2_Units   = Null,  
 @CTMP_Units   = Null,  
 @Dry_Strength_Facial_Units = Null,   
 @Dry_Strength_Tissue_Units = Null,  
 @Dry_Strength_Towel_Units = Null,  
 @Dye1_Units   = Null,  
 @Dye2_Units   = Null,  
 @Fiber1_Units   = Null,  
 @Fiber2_Units   = Null,  
 @Long_Fiber_Units  = Null,  
 @Product_Broke_Units  = Null,  
 @Short_Fiber_Units  = Null,  
 @Recycle_Fiber_Units  = Null,  
 @Softener_Tissue_Units  = Null,  
 @Softener_Towel_Units  = Null,  
 @Wet_Strength_Tissue_Units = Null,  
 @Wet_Strength_Towel_Units = Null,  
 @Aloe_E_Additive_Units  = Null,  
 @Softener_Facial_Units  = Null,  
 @Wet_Strength_Facial_Units = Null  
  
  
---------------------------------------------------------------------------------------------  
--  Get Language Tranlsation and other variables  
---------------------------------------------------------------------------------------------  
  
select  
@LanguageParmID  = 8,  
@LanguageId   = NULL  
  
SELECT @UserId = User_Id  
FROM Users  
WHERE UserName = @UserName  
  
SELECT @LanguageId = CASE WHEN isnumeric(ltrim(rtrim(Value))) = 1 THEN convert(float, ltrim(rtrim(Value)))  
    ELSE NULL  
    END  
FROM User_Parameters  
WHERE User_Id = @UserId  
 AND Parm_Id = @LanguageParmId  
  
IF @LanguageId IS NULL  
 BEGIN  
 SELECT @LanguageId = CASE   
WHEN isnumeric(ltrim(rtrim(Value))) = 1   
THEN convert(float, ltrim(rtrim(Value)))  
     ELSE NULL  
     END  
 FROM Site_Parameters  
 WHERE Parm_Id = @LanguageParmId  
  
 IF @LanguageId IS NULL  
  BEGIN  
  SELECT @LanguageId = 0  
  END  
 END  
  
  
select @NoDataMsg = GBDB.dbo.fnLocal_GlblTranslation('NO DATA meets the given criteria', @LanguageId)  
select @TooMuchDataMsg = GBDB.dbo.fnLocal_GlblTranslation('There are more results than can be displayed', @LanguageId)  
  
  
/************************************************************************************************  
*                                                                                                                               *  
*                                     Get Configuration                                                               *  
*                                                                                                                               *  
************************************************************************************************/  
/* Get the line id */  
Select @PL_Id = PL_Id  
From Prod_Lines  
Where PL_Desc = 'TT ' + ltrim(rtrim(@Line_Name))  
  
/* Get the plant and storage location from the Extended_Info field */  
Select @Extended_Info = Extended_Info  
From Prod_Lines  
Where PL_Id = @PL_Id  
  
Select @Flag_Start_Position = charindex(@Plant_Flag, upper(@Extended_Info), 0)  
If @Flag_Start_Position > 0  
     Begin  
     Select @Plant = right(@Extended_Info, len(@Extended_Info)-@Flag_Start_Position-len(@Plant_Flag)+1)  
     Select @Flag_End_Position = charindex(';', @Plant)  
     If @Flag_End_Position > 0  
          Select @Plant = left(@Plant, @Flag_End_Position-1)  
     End  
  
Select @Flag_Start_Position = charindex(@Storage_Location_Flag, upper(@Extended_Info), 0)  
If @Flag_Start_Position > 0  
     Begin  
     Select @Storage_Location = right(@Extended_Info, len(@Extended_Info)-@Flag_Start_Position-len(@Storage_Location_Flag)+1)  
     Select @Flag_End_Position = charindex(';', @Storage_Location)  
     If @Flag_End_Position > 0  
          Select @Storage_Location = left(@Storage_Location, @Flag_End_Position-1)  
     End  
  
/* Get Different PU Ids */  
Select @Production_PU_Id = PU_Id  
From Prod_Units  
Where PL_Id = @PL_Id And PU_Desc = @Line_Name + ' Production'  
  
Select @Rolls_PU_Id = PU_Id  
From Prod_Units  
Where PL_Id = @PL_Id And PU_Desc = @Line_Name + ' Rolls'  
  
Select @Materials_PU_Id = PU_Id  
From Prod_Units  
Where PL_Id = @PL_Id And PU_Desc = @Line_Name + ' Materials'  
  
/* Get tonnage variables */  
SELECT @Good_Tons_Var_Id = GBDB.dbo.fnLocal_GlblGetVarId(@Rolls_PU_Id, 'Tons Good')  
SELECT @Consumed_Tons_Var_Id = GBDB.dbo.fnLocal_GlblGetVarId(@Rolls_PU_Id, 'Tons Consumed')  
SELECT @Shipped_Tons_Var_Id = GBDB.dbo.fnLocal_GlblGetVarId(@Rolls_PU_Id, 'Tons Shipped')  
SELECT @Reject_Tons_Var_Id = GBDB.dbo.fnLocal_GlblGetVarId(@Rolls_PU_Id, 'Tons Reject')  
SELECT @Hold_Tons_Var_Id = GBDB.dbo.fnLocal_GlblGetVarId(@Rolls_PU_Id, 'Tons Hold')  
SELECT @Fire_Tons_Var_Id = GBDB.dbo.fnLocal_GlblGetVarId(@Rolls_PU_Id, 'Tons Fire')  
  
/* Get property for GCAS configuration */  
Select @Prop_Id = Prop_Id  
From Product_Properties  
Where Prop_Desc = 'Pmkg Parent Rolls'  
  
Select @Ratio_Spec_Id = Spec_Id  
From Specifications  
Where Prop_Id = @Prop_Id And Spec_Desc = 'Roll Ratio'  
  
--select var_desc, eng_units from variables where var_desc like '%Usage Hr Sum%'  
  
/* Get chemical variables */  
SELECT @3rd_Furnish_Var_Id = GBDB.dbo.fnLocal_GlblGetVarId(@Materials_PU_Id, '3rd Furnish Usage Hr Sum')  
SELECT @CTMP_Var_Id = GBDB.dbo.fnLocal_GlblGetVarId(@Materials_PU_Id, 'CTMP Usage Hr Sum')  
SELECT @Fiber_1_Var_Id = GBDB.dbo.fnLocal_GlblGetVarId(@Materials_PU_Id, 'Fiber 1 Usage Hr Sum')  
SELECT @Fiber_2_Var_Id = GBDB.dbo.fnLocal_GlblGetVarId(@Materials_PU_Id, 'Fiber 2 Usage Hr Sum')  
SELECT @Long_Fiber_Var_Id = GBDB.dbo.fnLocal_GlblGetVarId(@Materials_PU_Id, 'Long Fiber Usage Hr Sum')  
SELECT @Product_Broke_Var_Id = GBDB.dbo.fnLocal_GlblGetVarId(@Materials_PU_Id, 'Product Broke Usage Hr Sum')  
SELECT @Short_Fiber_Var_Id = GBDB.dbo.fnLocal_GlblGetVarId(@Materials_PU_Id, 'Short Fiber Usage Hr Sum')  
SELECT @Recycle_Fiber_Var_Id = GBDB.dbo.fnLocal_GlblGetVarId(@Materials_PU_Id, 'Recycle Fiber Usage Hr Sum')  
SELECT @Absorb_Aid_Towel_Var_Id = GBDB.dbo.fnLocal_GlblGetVarId(@Materials_PU_Id, 'Absorb Aid Towel Usage Hr Sum')  
SELECT @Aloe_E_Additive_Var_Id = GBDB.dbo.fnLocal_GlblGetVarId(@Materials_PU_Id, 'Aloe_E Additive Usage Hr Sum')  
SELECT @Cat_Promoter_Var_Id = GBDB.dbo.fnLocal_GlblGetVarId(@Materials_PU_Id, 'Cat Promoter Usage Hr Sum')  
SELECT @Chem_1_Var_Id = GBDB.dbo.fnLocal_GlblGetVarId(@Materials_PU_Id, 'Chem 1 Usage Hr Sum')  
SELECT @Chem_2_Var_Id = GBDB.dbo.fnLocal_GlblGetVarId(@Materials_PU_Id, 'Chem 2 Usage Hr Sum')  
SELECT @Dry_Strength_Facial_Var_Id = GBDB.dbo.fnLocal_GlblGetVarId(@Materials_PU_Id, 'Dry Strength Facial Usage Hr Sum')  
SELECT @Dry_Strength_Tissue_Var_Id = GBDB.dbo.fnLocal_GlblGetVarId(@Materials_PU_Id, 'Dry Strength Tissue Usage Hr Sum')  
SELECT @Dry_Strength_Towel_Var_Id = GBDB.dbo.fnLocal_GlblGetVarId(@Materials_PU_Id, 'Dry Strength Towel Usage Hr Sum')  
SELECT @Dye_1_Var_Id = GBDB.dbo.fnLocal_GlblGetVarId(@Materials_PU_Id, 'Dye 1 Usage Hr Sum')  
SELECT @Dye_2_Var_Id = GBDB.dbo.fnLocal_GlblGetVarId(@Materials_PU_Id, 'Dye 2 Usage Hr Sum')  
SELECT @Softener_Facial_Var_Id = GBDB.dbo.fnLocal_GlblGetVarId(@Materials_PU_Id, 'Softener Facial Usage Hr Sum')  
SELECT @Softener_Tissue_Var_Id = GBDB.dbo.fnLocal_GlblGetVarId(@Materials_PU_Id, 'Softener Tissue Usage Hr Sum')  
SELECT @Softener_Towel_Var_Id = GBDB.dbo.fnLocal_GlblGetVarId(@Materials_PU_Id, 'Softener Towel Usage Hr Sum')  
SELECT @Wet_Strength_Facial_Var_Id = GBDB.dbo.fnLocal_GlblGetVarId(@Materials_PU_Id, 'Wet Strength Facial Usage Hr Sum')  
SELECT @Wet_Strength_Tissue_Var_Id = GBDB.dbo.fnLocal_GlblGetVarId(@Materials_PU_Id, 'Wet Strength Tissue Usage Hr Sum')  
SELECT @Wet_Strength_Towel_Var_Id = GBDB.dbo.fnLocal_GlblGetVarId(@Materials_PU_Id, 'Wet Strength Towel Usage Hr Sum')  
  
  
/************************************************************************************************  
*                                                                                                                               *  
*                                     Get Production Statistics                                                   *  
*                                                                                                                               *  
************************************************************************************************/  
/* Open cursor for product runs */  
If @Report_Prod_Id Is Not Null And @Report_Prod_Id > 0  
     Declare ProductRuns Cursor Scroll For  
     Select  ps.Prod_Id,   
  p.Prod_Desc,  
  c.Char_Id,  
  left(c.Char_Desc, 8) As GCAS,  
  Case  When @Report_Start_Time > ps.Start_Time Then @Report_Start_Time  
   Else ps.Start_Time  
   End As Start_Time,   
  Case  When @Report_End_Time < ps.End_Time Or ps.End_Time Is Null Then @Report_End_Time  
   Else ps.End_Time  
   End As End_Time  
     From Production_Starts ps  
          Inner Join Products p On ps.Prod_Id = p.Prod_Id  
          Inner Join Characteristic_Groups cg On p.Prod_Code = cg.Characteristic_Grp_Desc And Prop_Id = @Prop_Id  
          Inner Join Characteristic_Group_Data cgd On cg.Characteristic_Grp_Id = cgd.Characteristic_Grp_Id  
          Inner Join Characteristics c On cgd.Char_Id = c.Char_Id  
     Where PU_Id = @Production_PU_Id And ps.Prod_Id = @Report_Prod_Id And  
  
                ps.Start_Time < @Report_End_Time And (ps.End_Time > @Report_Start_Time Or ps.End_Time Is Null)  
     Order By p.Prod_Desc Asc, GCAS Asc, Start_Time Asc  
     For Read Only  
Else  
     Declare ProductRuns Cursor Scroll For  
     Select  ps.Prod_Id,   
  p.Prod_Desc,  
  c.Char_Id,  
  left(c.Char_Desc, 8) As GCAS,  
  Case  When @Report_Start_Time > ps.Start_Time Then @Report_Start_Time  
   Else ps.Start_Time  
   End As Start_Time,   
  Case  When @Report_End_Time < ps.End_Time Or ps.End_Time Is Null Then @Report_End_Time  
   Else ps.End_Time  
   End As End_Time  
     From Production_Starts ps  
          Inner Join Products p On ps.Prod_Id = p.Prod_Id  
          Inner Join Characteristic_Groups cg On p.Prod_Code = cg.Characteristic_Grp_Desc And Prop_Id = @Prop_Id  
          Inner Join Characteristic_Group_Data cgd On cg.Characteristic_Grp_Id = cgd.Characteristic_Grp_Id  
          Inner Join Characteristics c On cgd.Char_Id = c.Char_Id  
     Where PU_Id = @Production_PU_Id And  
                ps.Start_Time < @Report_End_Time And (ps.End_Time > @Report_Start_Time Or ps.End_Time Is Null)  
     Order By p.Prod_Desc Asc, GCAS Asc, Start_Time Asc  
     For Read Only  
  
Open ProductRuns  
  
  
     Fetch First From ProductRuns Into @Prod_Id, @Prod_Desc, @GCAS_Char_Id, @GCAS, @Product_Start_Time, @Product_End_Time  
     Select  @Last_Prod_Id = @Prod_Id,  
  @Last_GCAS = @GCAS,  
  @Last_Prod_Desc = @Prod_Desc  
  
     While @@FETCH_STATUS = 0  
          Begin  
          /* Product Time */  
          Select @Product_Time = IsNull(@Product_Time, 0) + convert(float, datediff(s, @Product_Start_Time, @Product_End_Time))/60  
  
          /* Get Ratio */  
          Select @Ratio = convert(float, Target)/100  
          From Active_Specs asp  
          Where Char_Id = @GCAS_Char_Id And Spec_Id = @Ratio_Spec_Id And  
                Effective_Date <= @Product_Start_Time And (Expiration_Date > @Product_Start_Time Or Expiration_Date Is Null)  
  
          /************************************************************************************************  
          *                                        Production Tonnage/Counts                                          *  
          ************************************************************************************************/  
  
 --------------------  
   /* Good Tonnes */  
   Select @Total = sum(cast(Result As float)) * @Ratio,  
  @Count = count(Result)  
          From tests   
          Where ((Var_Id = @Good_Tons_Var_Id Or Var_Id = @Consumed_Tons_Var_Id Or Var_Id = @Shipped_Tons_Var_Id) and Result_On > @Product_Start_Time And Result_On <= @Product_End_Time And Result Is Not Null And cast(Result As float) > 0.0)  
  
          If @Count > 0  
               Select @Reel_Tons_Sum  = isnull(@Reel_Tons_Sum, 0) + isnull(@Total, 0)  
  
          /* Reject Tonnes */  
          Select @Total = sum(cast(Result As float)) * @Ratio,  
  @Count = count(Result)  
          From tests   
          Where Var_Id = @Reject_Tons_Var_Id and Result_On > @Product_Start_Time And Result_On <= @Product_End_Time And Result Is Not Null And cast(Result As float) > 0.0  
  
          If @Count > 0  
               Select @Reel_Tons_Sum  = isnull(@Reel_Tons_Sum, 0) + isnull(@Total, 0)  
  
          /* Fire Tonnes */  
          Select @Total = sum(cast(Result As float)) * @Ratio,  
  @Count = count(Result)  
          From tests   
          Where Var_Id = @Fire_Tons_Var_Id and Result_On > @Product_Start_Time And Result_On <= @Product_End_Time And Result Is Not Null And cast(Result As float) > 0.0  
  
          If @Count > 0  
               Select @Reel_Tons_Sum  = isnull(@Reel_Tons_Sum, 0) + isnull(@Total, 0)  
  
          /* Hold Tonnes */  
          Select @Total = sum(cast(Result As float)) * @Ratio,  
  @Count = count(Result)  
          From tests   
          Where Var_Id = @Hold_Tons_Var_Id and Result_On > @Product_Start_Time And Result_On <= @Product_End_Time And Result Is Not Null And cast(Result As float) > 0.0  
  
          If @Count > 0  
               Select @Reel_Tons_Sum  = isnull(@Reel_Tons_Sum, 0) + isnull(@Total, 0)  
  
 --------------------  
  
          /************************************************************************************************  
          *                                           Materials                                           *  
          ************************************************************************************************/  
          /* Furnishes */  
          If @3rd_Furnish_Var_Id Is Not Null  
               Select @3rd_Furnish_Sum = IsNull(@3rd_Furnish_Sum, 0) + IsNull(Sum(cast(Result As float)), 0) * @Ratio From tests Where Result_On > @Product_Start_Time And Result_On <= @Product_End_Time And Var_Id = @3rd_Furnish_Var_Id  
          If @CTMP_Var_Id Is Not Null  
               Select @CTMP_Sum = IsNull(@CTMP_Sum, 0) + IsNull(Sum(cast(Result As float)), 0) * @Ratio From tests Where Result_On > @Product_Start_Time And Result_On <= @Product_End_Time And Var_Id = @CTMP_Var_Id  
          If @Fiber_1_Var_Id Is Not Null  
               Select @Fiber_1_Sum = IsNull(@Fiber_1_Sum, 0) + IsNull(Sum(cast(Result As float)), 0) * @Ratio From tests Where Result_On > @Product_Start_Time And Result_On <= @Product_End_Time And Var_Id = @Fiber_1_Var_Id  
          If @Fiber_2_Var_Id Is Not Null  
               Select @Fiber_2_Sum = IsNull(@Fiber_2_Sum, 0) + IsNull(Sum(cast(Result As float)), 0) * @Ratio From tests Where Result_On > @Product_Start_Time And Result_On <= @Product_End_Time And Var_Id = @Fiber_2_Var_Id  
          If @Long_Fiber_Var_Id Is Not Null  
               Select @Long_Fiber_Sum = IsNull(@Long_Fiber_Sum, 0) + IsNull(Sum(cast(Result As float)), 0) * @Ratio From tests Where Result_On > @Product_Start_Time And Result_On <= @Product_End_Time And Var_Id = @Long_Fiber_Var_Id  
          If @Short_Fiber_Var_Id Is Not Null  
               Select @Short_Fiber_Sum = IsNull(@Short_Fiber_Sum, 0) + IsNull(Sum(cast(Result As float)), 0) * @Ratio From tests Where Result_On > @Product_Start_Time And Result_On <= @Product_End_Time And Var_Id = @Short_Fiber_Var_Id  
          If @Recycle_Fiber_Var_Id Is Not Null  
               Select @Recycle_Fiber_Sum = IsNull(@Recycle_Fiber_Sum, 0) + IsNull(Sum(cast(Result As float)), 0) * @Ratio From tests Where Result_On > @Product_Start_Time And Result_On <= @Product_End_Time And Var_Id = @Recycle_Fiber_Var_Id  
  
  
          /* Chemicals */  
          If @Absorb_Aid_Towel_Var_Id Is Not Null  
               Select @Absorb_Aid_Towel_Sum = IsNull(@Absorb_Aid_Towel_Sum, 0) + IsNull(Sum(cast(Result As float)), 0) * @Ratio From tests Where Result_On > @Product_Start_Time And Result_On <= @Product_End_Time And Var_Id = @Absorb_Aid_Towel_Var_Id  
          If @Aloe_E_Additive_Var_Id Is Not Null  
               Select @Aloe_E_Additive_Sum = IsNull(@Aloe_E_Additive_Sum, 0) + IsNull(Sum(cast(Result As float)), 0) * @Ratio From tests Where Result_On > @Product_Start_Time And Result_On <= @Product_End_Time And Var_Id = @Aloe_E_Additive_Var_Id  
          If @Cat_Promoter_Var_Id Is Not Null  
               Select @Cat_Promoter_Sum = IsNull(@Cat_Promoter_Sum, 0) + IsNull(Sum(cast(Result As float)), 0) * @Ratio From tests Where Result_On > @Product_Start_Time And Result_On <= @Product_End_Time And Var_Id = @Cat_Promoter_Var_Id  
          If @Chem_1_Var_Id Is Not Null  
               Select @Chem_1_Sum = IsNull(@Chem_1_Sum, 0) + IsNull(Sum(cast(Result As float)), 0) * @Ratio From tests Where Result_On > @Product_Start_Time And Result_On <= @Product_End_Time And Var_Id = @Chem_1_Var_Id  
          If @Chem_2_Var_Id Is Not Null  
               Select @Chem_2_Sum = IsNull(@Chem_2_Sum, 0) + IsNull(Sum(cast(Result As float)), 0) * @Ratio From tests Where Result_On > @Product_Start_Time And Result_On <= @Product_End_Time And Var_Id = @Chem_2_Var_Id  
          If @Dry_Strength_Facial_Var_Id Is Not Null  
               Select @Dry_Strength_Facial_Sum = IsNull(@Dry_Strength_Facial_Sum, 0) + IsNull(Sum(cast(Result As float)), 0) * @Ratio From tests Where Result_On > @Product_Start_Time And Result_On <= @Product_End_Time And Var_Id = @Dry_Strength_Facial_Var_Id  
          If @Dry_Strength_Tissue_Var_Id Is Not Null  
               Select @Dry_Strength_Tissue_Sum = IsNull(@Dry_Strength_Tissue_Sum, 0) + IsNull(Sum(cast(Result As float)), 0) * @Ratio From tests Where Result_On > @Product_Start_Time And Result_On <= @Product_End_Time And Var_Id = @Dry_Strength_Tissue_Var_Id  
          If @Dry_Strength_Towel_Var_Id Is Not Null  
               Select @Dry_Strength_Towel_Sum = IsNull(@Dry_Strength_Towel_Sum, 0) + IsNull(Sum(cast(Result As float)), 0) * @Ratio From tests Where Result_On > @Product_Start_Time And Result_On <= @Product_End_Time And Var_Id = @Dry_Strength_Towel_Var_Id
  
          If @Dye_1_Var_Id Is Not Null  
               Select @Dye_1_Sum = IsNull(@Dye_1_Sum, 0) + IsNull(Sum(cast(Result As float)), 0) * @Ratio From tests Where Result_On > @Product_Start_Time And Result_On <= @Product_End_Time And Var_Id = @Dye_1_Var_Id  
          If @Dye_2_Var_Id Is Not Null  
               Select @Dye_2_Sum = IsNull(@Dye_2_Sum, 0) + IsNull(Sum(cast(Result As float)), 0) * @Ratio From tests Where Result_On > @Product_Start_Time And Result_On <= @Product_End_Time And Var_Id = @Dye_2_Var_Id  
          If @Product_Broke_Var_Id Is Not Null  
               Select @Product_Broke_Sum = IsNull(@Product_Broke_Sum, 0) + IsNull(Sum(cast(Result As float)), 0) * @Ratio From tests Where Result_On > @Product_Start_Time And Result_On <= @Product_End_Time And Var_Id = @Product_Broke_Var_Id  
          If @Softener_Facial_Var_Id Is Not Null  
               Select @Softener_Facial_Sum = IsNull(@Softener_Facial_Sum, 0) + IsNull(Sum(cast(Result As float)), 0) * @Ratio From tests Where Result_On > @Product_Start_Time And Result_On <= @Product_End_Time And Var_Id = @Softener_Facial_Var_Id  
          If @Softener_Tissue_Var_Id Is Not Null  
               Select @Softener_Tissue_Sum = IsNull(@Softener_Tissue_Sum, 0) + IsNull(Sum(cast(Result As float)), 0) * @Ratio From tests Where Result_On > @Product_Start_Time And Result_On <= @Product_End_Time And Var_Id = @Softener_Tissue_Var_Id  
          If @Softener_Towel_Var_Id Is Not Null  
               Select @Softener_Towel_Sum = IsNull(@Softener_Towel_Sum, 0) + IsNull(Sum(cast(Result As float)), 0) * @Ratio From tests Where Result_On > @Product_Start_Time And Result_On <= @Product_End_Time And Var_Id = @Softener_Towel_Var_Id  
          If @Wet_Strength_Facial_Var_Id Is Not Null  
               Select @Wet_Strength_Facial_Sum = IsNull(@Wet_Strength_Facial_Sum, 0) + IsNull(Sum(cast(Result As float)), 0) * @Ratio From tests Where Result_On > @Product_Start_Time And Result_On <= @Product_End_Time And Var_Id = @Wet_Strength_Facial_Var_Id  
          If @Wet_Strength_Tissue_Var_Id Is Not Null  
               Select @Wet_Strength_Tissue_Sum = IsNull(@Wet_Strength_Tissue_Sum, 0) + IsNull(Sum(cast(Result As float)), 0) * @Ratio From tests Where Result_On > @Product_Start_Time And Result_On <= @Product_End_Time And Var_Id = @Wet_Strength_Tissue_Var_Id  
          If @Wet_Strength_Towel_Var_Id Is Not Null  
               Select @Wet_Strength_Towel_Sum = IsNull(@Wet_Strength_Towel_Sum, 0) + IsNull(Sum(cast(Result As float)), 0) * @Ratio From tests Where Result_On > @Product_Start_Time And Result_On <= @Product_End_Time And Var_Id = @Wet_Strength_Towel_Var_Id
  
  
  
          /************************************************************************************************  
          *                                     Get Next Record                                           *  
          ************************************************************************************************/  
          Fetch Next From ProductRuns Into @Prod_Id, @Prod_Desc, @GCAS_Char_Id, @GCAS, @Product_Start_Time, @Product_End_Time  
  
          /************************************************************************************************  
          *                                     Return Results                                            *  
          ************************************************************************************************/  
          /* If finished adding up data for a single product or no more products then return data */  
          If (@Last_Prod_Id <> @Prod_Id And @Last_GCAS <> @GCAS) Or @@FETCH_STATUS <> 0  
               Begin  
               /* Get total furnish */  
               Select @Furnish_Sum =  isnull(@3rd_Furnish_Sum, 0) + isnull(@CTMP_Sum, 0) +  isnull(@Fiber_1_Sum, 0) + isnull(@Fiber_2_Sum, 0) +  isnull(@Long_Fiber_Sum, 0) +  isnull(@Short_Fiber_Sum, 0) +  isnull(@Recycle_Fiber_Sum, 0) +  isnull(@Product_Broke_Sum, 0)  
  
  
 ---------------------------------------------------------------------------------------------  
 -- get eng_units  
 ---------------------------------------------------------------------------------------------  
  
          /* Furnishes */  
          If @3rd_Furnish_Var_Id Is Not Null  
               Select @Third_Furnish_Units = eng_units From variables where Var_Id = @3rd_Furnish_Var_Id  
          If @CTMP_Var_Id Is Not Null  
               Select @CTMP_Units = eng_units From variables where Var_Id = @CTMP_Var_Id  
          If @Fiber_1_Var_Id Is Not Null  
               Select @Fiber1_Units = eng_units From variables where Var_Id = @Fiber_1_Var_Id  
          If @Fiber_2_Var_Id Is Not Null  
               Select @Fiber2_Units = eng_units From variables where Var_Id = @Fiber_2_Var_Id  
          If @Long_Fiber_Var_Id Is Not Null  
               Select @Long_Fiber_Units = eng_units From variables where Var_Id = @Long_Fiber_Var_Id  
          If @Short_Fiber_Var_Id Is Not Null  
               Select @Short_Fiber_Units = eng_units From variables where Var_Id = @Short_Fiber_Var_Id  
          If @Recycle_Fiber_Var_Id Is Not Null  
               Select @Recycle_Fiber_Units = eng_units From variables where Var_Id = @Recycle_Fiber_Var_Id  
  
  
      /* Chemicals */  
          If @Absorb_Aid_Towel_Var_Id Is Not Null  
               Select @Absorb_Aid_Towel_Units = eng_units From variables where Var_Id = @Absorb_Aid_Towel_Var_Id  
          If @Aloe_E_Additive_Var_Id Is Not Null  
               Select @Aloe_E_Additive_Units = eng_units From variables where Var_Id = @Aloe_E_Additive_Var_Id  
          If @Cat_Promoter_Var_Id Is Not Null  
               Select @Cat_Promoter_Units = eng_units From variables where Var_Id = @Cat_Promoter_Var_Id  
          If @Chem_1_Var_Id Is Not Null  
               Select @Chem1_Units = eng_units From variables where Var_Id = @Chem_1_Var_Id  
          If @Chem_2_Var_Id Is Not Null  
               Select @Chem2_Units = eng_units From variables where Var_Id = @Chem_2_Var_Id  
          If @Dry_Strength_Facial_Var_Id Is Not Null  
               Select @Dry_Strength_Facial_Units = eng_units From variables where Var_Id = @Dry_Strength_Facial_Var_Id  
          If @Dry_Strength_Tissue_Var_Id Is Not Null  
               Select @Dry_Strength_Tissue_Units = eng_units From variables where Var_Id = @Dry_Strength_Tissue_Var_Id  
          If @Dry_Strength_Towel_Var_Id Is Not Null  
               Select @Dry_Strength_Towel_Units = eng_units From variables where Var_Id = @Dry_Strength_Towel_Var_Id  
          If @Dye_1_Var_Id Is Not Null  
               Select @Dye1_Units = eng_units From variables where Var_Id = @Dye_1_Var_Id  
          If @Dye_2_Var_Id Is Not Null  
               Select @Dye2_Units = eng_units From variables where Var_Id = @Dye_2_Var_Id  
          If @Product_Broke_Var_Id Is Not Null  
               Select @Product_Broke_Units = eng_units From variables where Var_Id = @Product_Broke_Var_Id  
          If @Softener_Facial_Var_Id Is Not Null  
               Select @Softener_Facial_Units = eng_units From variables where Var_Id = @Softener_Facial_Var_Id  
          If @Softener_Tissue_Var_Id Is Not Null  
               Select @Softener_Tissue_Units = eng_units From variables where Var_Id = @Softener_Tissue_Var_Id  
          If @Softener_Towel_Var_Id Is Not Null  
               Select @Softener_Towel_units = eng_units From variables where Var_Id = @Softener_Towel_Var_Id  
          If @Wet_Strength_Facial_Var_Id Is Not Null  
               Select @Wet_Strength_Facial_Units = eng_units From variables where Var_Id = @Wet_Strength_Facial_Var_Id  
          If @Wet_Strength_Tissue_Var_Id Is Not Null  
               Select @Wet_Strength_Tissue_Units = eng_units From variables where Var_Id = @Wet_Strength_Tissue_Var_Id  
          If @Wet_Strength_Towel_Var_Id Is Not Null  
               Select @Wet_Strength_Towel_Units = eng_units From variables where Var_Id = @Wet_Strength_Towel_Var_Id  
  
  
               /* Insert Data */  
               Insert Into #Summary_Data (Plant,  
     Storage_Location,   
     Product,  
     GCAS,  
     Reel_Tons,  
     Furnish,  
     Third_Furnish,  
     Absorb_Aid_Towel,  
     Cat_Promoter,  
     Chem_1,  
     Chem_2,  
     CTMP,  
     Dry_Strength_Tissue,  
     Dry_Strength_Towel,  
     Dye_1,  
     Dye_2,  
     Fiber_1,  
     Fiber_2,  
     Long_Fiber,  
     Product_Broke,  
     Short_Fiber,  
     Recycle_Fiber,  
     Softener_Tissue,  
     Softener_Towel,  
     Wet_Strength_Tissue,  
     Wet_Strength_Towel,  
     Aloe_E_Additive,  
     Softener_Facial,  
     Wet_Strength_Facial,  
     Dry_Strength_Facial,  
     Third_Furnish_Units,  
     Absorb_Aid_Towel_Units,  
     Cat_Promoter_Units,  
     Chem1_Units,  
     Chem2_Units,  
     CTMP_Units,  
     Dry_Strength_Facial_Units,  
     Dry_Strength_Tissue_Units,  
     Dry_Strength_Towel_Units,  
     Dye1_Units,  
     Dye2_Units,  
     Fiber1_Units,  
     Fiber2_Units,  
     Long_Fiber_Units,  
     Product_Broke_Units,  
     Short_Fiber_Units,  
     Recycle_Fiber_Units,  
     Softener_Tissue_Units,  
     Softener_Towel_Units,  
     Wet_Strength_Tissue_Units,  
     Wet_Strength_Towel_Units,  
     Aloe_E_Additive_Units,  
     Softener_Facial_Units,  
     Wet_Strength_Facial_Units       )  
                Values (  @Plant,  
     @Storage_Location,  
     @Last_Prod_Desc,  
     @Last_GCAS,  
     @Reel_Tons_Sum,  
     @Furnish_Sum,   
     @3rd_Furnish_Sum,   
     @Absorb_Aid_Towel_Sum,   
     @Cat_Promoter_Sum,   
     @Chem_1_Sum,   
     @Chem_2_Sum,   
     @CTMP_Sum,   
     @Dry_Strength_Tissue_Sum,   
     @Dry_Strength_Towel_Sum,   
     @Dye_1_Sum,   
     @Dye_2_Sum,   
     @Fiber_1_Sum,   
     @Fiber_2_Sum,   
     @Long_Fiber_Sum,   
     @Product_Broke_Sum,   
     @Short_Fiber_Sum,   
     @Recycle_Fiber_Sum,  
     @Softener_Tissue_Sum,   
     @Softener_Towel_Sum,   
     @Wet_Strength_Tissue_Sum,   
     @Wet_Strength_Towel_Sum,   
     @Aloe_E_Additive_Sum,  
     @Softener_Facial_Sum,  
     @Wet_Strength_Facial_Sum,  
     @Dry_Strength_Facial_Sum,  
     @Third_Furnish_Units,  
     @Absorb_Aid_Towel_Units,  
     @Cat_Promoter_Units,  
     @Chem1_Units,  
     @Chem2_Units,  
     @CTMP_Units,  
     @Dry_Strength_Facial_Units,  
     @Dry_Strength_Tissue_Units,  
     @Dry_Strength_Towel_Units,  
     @Dye1_Units,  
     @Dye2_Units,  
     @Fiber1_Units,  
     @Fiber2_Units,  
     @Long_Fiber_Units,  
     @Product_Broke_Units,  
     @Short_Fiber_Units,  
     @Recycle_Fiber_Units,  
     @Softener_Tissue_Units,  
     @Softener_Towel_Units,  
     @Wet_Strength_Tissue_Units,  
     @Wet_Strength_Towel_Units,  
     @Aloe_E_Additive_Units,  
     @Softener_Facial_Units,  
     @Wet_Strength_Facial_Units  
     )  
  
               If @@FETCH_STATUS = 0  
                    Begin  
                    /* Reinitialize */  
                    Select  @Product_Time  = Null,  
   @Reel_Tons_Sum    = Null,  
   @Furnish_Sum   = Null,  
   @3rd_Furnish_Sum   = Null,  
   @Absorb_Aid_Towel_Sum   = Null,  
   @Aloe_E_Additive_Sum   = Null,  
   @Cat_Promoter_Sum   = Null,  
   @Chem_1_Sum    = Null,  
   @Chem_2_Sum    = Null,  
   @CTMP_Sum    = Null,  
   @Dry_Strength_Facial_Sum = Null,  
   @Dry_Strength_Tissue_Sum = Null,  
   @Dry_Strength_Towel_Sum  = Null,  
   @Dye_1_Sum    = Null,  
   @Dye_2_Sum    = Null,  
   @Fiber_1_Sum    = Null,  
   @Fiber_2_Sum    = Null,  
   @Long_Fiber_Sum   = Null,  
   @Product_Broke_Sum   = Null,  
   @Short_Fiber_Sum   = Null,  
   @Recycle_Fiber_Sum  = Null,  
   @Softener_Facial_Sum  = Null,  
   @Softener_Tissue_Sum  = Null,  
   @Softener_Towel_Sum  = Null,  
   @Wet_Strength_Facial_Sum = Null,  
   @Wet_Strength_Tissue_Sum = Null,  
   @Wet_Strength_Towel_Sum  = Null,  
   @Last_Prod_Id    = @Prod_Id,  
   @Last_Prod_Desc   = @Prod_Desc,  
   @Last_GCAS   = @GCAS,  
   @Third_Furnish_Units   = Null,  
   @Absorb_Aid_Towel_Units  = Null,  
   @Cat_Promoter_Units  = Null,  
   @Chem1_Units   = Null,  
   @Chem2_Units   = Null,  
   @CTMP_Units   = Null,  
   @Dry_Strength_Facial_Units = Null,   
   @Dry_Strength_Tissue_Units = Null,  
   @Dry_Strength_Towel_Units = Null,  
   @Dye1_Units   = Null,  
   @Dye2_Units   = Null,  
   @Fiber1_Units   = Null,  
   @Fiber2_Units   = Null,  
   @Long_Fiber_Units  = Null,  
   @Product_Broke_Units  = Null,  
   @Short_Fiber_Units  = Null,  
   @Recycle_Fiber_Units  = Null,  
   @Softener_Tissue_Units  = Null,  
   @Softener_Towel_Units  = Null,  
   @Wet_Strength_Tissue_Units = Null,  
   @Wet_Strength_Towel_Units = Null,  
   @Aloe_E_Additive_Units  = Null,  
   @Softener_Facial_Units  = Null,  
   @Wet_Strength_Facial_Units = Null  
  
                    End  
               End  
          End  
  
  
Close ProductRuns  
Deallocate ProductRuns  
  
  
/************************************************************************************************  
*                                   Return Data                                                                        *  
************************************************************************************************/  
  
ReturnResultSets:  
  
----------------------------------------------------------------------------------------------------  
-- Error Messages.  
----------------------------------------------------------------------------------------------------    
  
IF (SELECT count(*) FROM @ErrorMessages) > 0  
 SELECT ErrMsg  
 FROM @ErrorMessages  
   
ELSE  
 BEGIN  
  
  -------------------------------------------------------------------------------  
  -- Error Messages.  
  -------------------------------------------------------------------------------  
  SELECT ErrMsg  
  FROM @ErrorMessages  
  
  select @SQL =   
  case  
  when (select count(*) from #Summary_Data) > 65000 then   
  'select ' + char(39) + @TooMuchDataMsg + char(39) + ' [User Notification Msg]'  
  when (select count(*) from #Summary_Data) = 0 then   
  'select ' + char(39) + @NoDataMsg + char(39) + ' [User Notification Msg]'  
  else GBDB.dbo.fnLocal_RptTableTranslation('#Summary_Data', @LanguageId)  
  end  
  
  exec (@sql)  
  
 end  
  
  
Drop Table #Summary_Data  
  
  

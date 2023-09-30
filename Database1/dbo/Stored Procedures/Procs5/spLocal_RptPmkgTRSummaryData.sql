  /*  
Stored Procedure: spLocal_RptPmkgTRSummaryData  
Author:   Matt Wells (MSI)  
Date Created:  04/23/02  
  
Description:  
=========  
This procedure provides Time Range Summary data for a given Line and Time Period.  
  
  
INPUTS: Start Time  
 End Time  
 Production Line Name (without the TT prefix)  
 Data Category  = 'Production'  
 Product ID for Report 0:  Returns summary data grouped by Product for all Products run in time period specified  
    Product ID: Returns summary data for this Product ID in time period specified  
  
CALLED BY:  RptPmkgTimeRangeSummary.xlt (Excel/VBA Template)  
  
CALLS: None  
  
Revision Change Date Who What  
======== =========== ==== =====  
0  4/23/02  MW Original Creation  
1  5/1/02  CE Numerous enhancements for Time Range Summary Rpt  
2  5/22/02  CE Adjust report end time to current time if in the future; Aggregate values by Product  
3  5/23/02  CE Rearranged columns returned to fix mismatch with template formula refs  
3.1  6/10/02  CE Fixed Downtime and SheetBreaks PU Ids (flip-flopped for Invalid_Status_Id query)  
3.2  4/11/02  DH Updated precision for @TNE_Conversion and @KG_Conversion  
3.3  11/08/02 KH Modifed Good Tons Sum to include Consumed and Shipped Tons  
3.4  02/03/03 MKW Changed tonnages variables to tonnage by time variables  
3.5  04/08/03 FLD Changed Electric, Gas, Water and Air variables from float to DECIMAL(15,2)  
3.6  04/10/03 KAH Added new materials Aloe_E_Additive, Softener_Facial, Wet_Strength_Facial, Dry_Strength_Facial  
  
4.0 7-Jul-03 S.Poon  Instead of returning #SummaryData as 1 ResultSet, the ResultSet has been  
     Broken down into 18 ResultSets. Each Result Set includes the Data and the Summary Calculations  
     All these changes are initiated because of the requirements of the dynamic rows in Excel  
  
4.1 01/26/03 JSJ  - Added code to drop the sp if it exists, and code to assign permissions after   
       the new sp has been created.  
     - Added #ErrMessages.  
     - Added calls for #ErrMessages to the result sets.    
     - Added validation checks for the input parameters.  
     - Removed use of @Data_Category and @Report_Prod_ID input variables.  
     - Change sp name to "spLocal_RptPmkgTRSummaryData".  
  
4.2 01/27/04 JSJ  - Changed comparisons of Var_Desc vs. hard-coded values so that the comparison    
       is 'GlblDesc=[Global Var_Desc]' in extended-info with a hard-coded value.    
       Note that for this stored procedure to work now, the extended-info information   
       in Variables must be updated accordlingly  
     - Added RA_Tons fields to summary temp tables and related variables to mirror   
       everything done with the TAY fields in the summary temp tables and the related   
       variables.  This new field is not added to the result sets, but is used in the   
       calculation for UNXP Tons.  
  
4.3 01/28/04 JSJ  - Added input parameters @RptConvertTNE and @RptConvertKG.  
     - Set conversions for TNE and KG to use these new parameters.           
  
4.4 02/03/04 FLD  Changed all DECIMAL(x,x) fields/variables to FLOAT to resolve overflow problems   
     once and for all.  
  
4.5 2004-FEB-17 FLD  Added "convert(float," to the DATEDIFF calculations for @GE_Uptime and @GI_Uptime.  We  
     were not getting any decimals in our hours without it.  
  
4.6 2004-FEB-18 FLD  - Changed the line status references intended to differentiate run and down hours into  
       Global Included and Global Excluded, to correct for incorrect reference to Global  
       Included Non-Run.    
     - Clarified the downtime and uptime variables names to make it clear which were global   
       included and which were global excluded.  
     - Corrected logic flaw in the partitioning of hours out into the global included and  
       excluded "buckets".  The start time of each record in the Line_Status cursor needed  
       to be associated with the line status of the PREVIOUS record in the cursor [or TOP 1  
       for the most recent record outside the cursor] in order to put the right status   
       against the right block of time.  
  
4.7 2004-FEB-21 FLD  Changed all 'real' data types to 'float'.  
  
4.8 2004-MAR-05 Langdon Davis - Added code for the 'Received' status ID and to add rolls with this status into  
       the count for Good Rolls.  Note: Rolls with a Received status are already included  
       in the 'Consumed_Tons' variable via the Proficy calculation definition so there is  
                            no need to add any code to get "Received_Tons".  
     - Cleaned out the commented out code referring to the var_desc field.  
  
4.9 2004-MAR-17 Langdon Davis It was discovered that the "Slab Tons By Time" variable is really in KG's.  Modified  
     the code accordingly.  Also, in the process, double checked "Teardown Tons By Time"--it  
     was indeed in TNE but the test result was being multipled by 1000 only to then be  
     diveded by 1000 in the results set formation.  Eliminated the unecessary math.  
   
5.0 2004-APR-2 Langdon Davis - Modified the code to automatically get 'HP Steam 1 Mass Flow In Hour Sum' for 1M   
       and 'Steam Mass Flow Hr Sum' for all other Mehoopany machines and for Cape's   
       machines, in place of the current 'Steam Usage Hr Sum'.  THIS CUSTOMIZATION IS   
       TEMPORARY WHILE FINAL REQUIREMENTS ARE BEING DETERMINED!!!  
     - Removed the @KG_Conversion being applied to the Steam numbers since 'Steam Usage   
       Hr Sum' is in MMBTU [so dividing by a KG conversion factor doesn't make sense] and,  
       in the case of Mehoopany, they preferred the Mlbs that the Steam Mass Flow variables  
       are already in.    
     - Removed the @KG_Conversion being applied to the Air numbers to allow the data to come  
       to be reported in whatever units the variable happens to be at that site.  
     - Added the Steam, Electric, Gas and Water UOM's to the temp tables and results  
       sets so the user will know what units the data are in.  
    
5.1 2004-12-01 Jeff Jaeger - brought this sp up to date with Checklist 110804.  
     - removed unused code.  
     - converted temp tables to table variables.  
  
5.11 2005-JAN-28 Langdon Davis - Modified/clarified field names to correspond to the change made on variable  
       names with Rev4.60.  
  
5.12 2005-09-01 Jeff Jaeger  
     - inserted code that will add rolls with a Perfect status and Quarantine status into the Good_Roll_Count.  
  
5.13 2005-11-01 Namho Kim -For Perfect Parent roll, Good and Quarantine changed to Not Perfect and Flagged.  
  
5.14 2005-11-22 Namho Kim -Changed to use both status(Good and not perfect, Quarantine and Flangged) for non perfect parent roll using sites.  
    
  
  
*/  
  
CREATE          PROCEDURE dbo.spLocal_RptPmkgTRSummaryData  
--declare  
  
 @Report_Start_Time datetime,  
 @Report_End_Time datetime,  
 @Line_Name   varchar(50),  
 @RptConvertTNE  varchar(50),  
 @RptConvertKG  varchar(50)  
  
AS  
  
Declare @Time1 datetime, @Time2 datetime, @Time3 datetime, @Time4 datetime, @Time5 datetime  
/* Testing...   
  
Select  @Report_Start_Time  = '2005-11-21 07:00:00',  
 @Report_End_Time    = '2005-11-22 07:00:00',  
 @Line_Name  = 'AZM2',  
 @RptConvertTNE  = '1.102311',  
 @RptConvertKG  = '2.2046'  
  
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
*                                        Declarations                     *  
*                                                                                               *  
************************************************************************************************/  
declare @Production_Runs table  
(  
 Start_Id int Primary Key,  
 Prod_Id  int   Not Null,  
 Prod_Desc varchar(50),  
 Start_Time datetime  Not Null,  
 End_Time datetime  Not Null  
)  
  
declare @Quality_Variables table  
(  
 Var_Id  int Primary Key,  
 Var_Desc varchar(50)  
)  
  
declare @Summary_Data table  
(  
 Product      varchar(50),  
 Product_Time     float,  
 Good_Tons     float,   
 Reject_Tons     float,   
 Hold_Tons     float,   
 Fire_Tons     float,  
 Slab      float,  
 Teardown     float,  
 Repulper_Tons     float,  
 TAY      float,  
 RA_Tons      float,  
 SheetBreak_Time     float,  
 GI_Downtime     float,  
 Cleaning_Blades     float,  
 Creping_Blades     float,  
 Good_Roll_Count     int,  
 Reject_Roll_Count    int,  
 Hold_Roll_Count     int,  
 Fire_Roll_Count     int,  
 Sheetbreak_Count    int,  
 Forming_Wire_Life    float,  
 Backing_Wire_Life    float,  
 Belt_Life     float,  
 Third_Furnish     float,  
 Absorb_Aid_Towel    float,  
 Aloe_E_Additive     float,  
 Biocide      float,  
 Cat_Promoter     float,  
 Chem_1      float,  
 Chem_2      float,  
 Chlorine_Control    float,  
 CTMP      float,  
 Defoamer     float,  
 Dry_Strength_Facial    float,  
 Dry_Strength_Tissue    float,  
 Dry_Strength_Towel    float,  
 Dye_1      float,  
 Dye_2      float,  
 Emulsion_1     float,  
 Emulsion_2     float,  
 Fiber_1      float,  
 Fiber_2      float,  
 Flocculant     float,  
 Glue_Adhesive     float,  
 Glue_Crepe_Aid     float,  
 Glue_Release_Aid    float,  
 Glue_Total     float,  
 Long_Fiber     float,  
 Machine_Broke     float,  
 pH_Control_Tissue_Acid    float,  
 pH_Control_Towel_Base    float,  
 Product_Broke     float,  
 Short_Fiber     float,  
 Single_Glue     float,  
 Softener_Facial     float,  
 Softener_Tissue     float,  
 Softener_Towel     float,  
 Steam      float,  
 Steam_UOM     varchar(15),  
 Air      float,  
 Air_UOM      varchar(15),  
 Wet_Strength_Facial    float,  
 Wet_Strength_Tissue    float,  
 Wet_Strength_Towel    float,  
 Basis_Weight_Manual_Avg    float,  
 Caliper_Average_Roll_A_Avg   float,  
 Caliper_Average_Roll_B_Avg    float,  
 Caliper_Range_Roll_A_Avg    float,  
 Caliper_Range_Roll_B_Avg    float,  
 Color_A_Value_Avg     float,  
 Color_B_Value_Avg     float,  
 Color_L_Value_Avg     float,  
 Holes_Large_Measurement_Avg    float,  
 Holes_Small_Avg_Avg     float,  
 Sink_Average_Avg     float,  
 Soft_Tissue_DS_SD_AVG_Avg    float,  
 Soft_Tissue_DS_WR_AVG_Avg    float,  
 Soft_Tissue_TS_SD_AVG_Avg    float,  
 Soft_Tissue_TS_WR_AVG_Avg    float,  
 Specks_Gross_Avg_Avg     float,  
 Specks_Large_Avg_Avg     float,  
 Specks_Red_Avg_Avg     float,  
 Specks_Small_Avg_Avg     float,  
 Specks_Tiny_Avg_Avg     float,  
 Stretch_CD_Avg      float,  
 Stretch_MD_Avg     float,  
 Tensile_CD_Avg      float,  
 Tensile_MD_Avg     float,  
 Tensile_Modulus_CD_Avg     float,  
 Tensile_Modulus_GM_Avg     float,  
 Tensile_Modulus_MD_Avg     float,  
 Tensile_Ratio_Avg     float,  
 Tensile_Total_Avg     float,  
 Wet_Burst_Average_Avg     float,  
 Wet_Tensile_Average_Avg    float,  
 Wet_Tensile_CD_Avg     float,  
 Wet_Tensile_MD_Avg     float,  
 Wet_Tensile_Ratio_Avg     float,  
 Wet_Tensile_Total_Avg     float,  
 Wet_Dry_Tissue_Ratio_Avg    float,  
 Wet_Dry_Towel_Ratio_Avg    float,  
 Downtime_Count     int,  
 GE_Downtime     float,  
 GI_Uptime     float,  
 GE_Uptime     float,  
 Yankee_Speed     float,  
 Reel_Speed     float,  
 Electric     float,  
 Electric_UOM     varchar(15),  
 Gas      float,  
 Gas_UOM      varchar(15),  
 Water      float,  
 Water_UOM     varchar(15)  
)  
  
  
declare @ErrorMessages table   
(  
 ErrMsg  nVarChar(255)   
)  
  
  
/*-----------------------------------------------------------------------------------  
* Validate the input parameters  
-------------------------------------------------------------------------------------*/  
  
  
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
  
IF @Line_Name is null or Isnumeric(@Line_Name) = 1 or len(@Line_Name) = 0   
BEGIN  
 INSERT @ErrorMessages (ErrMsg)  
  VALUES ('@Line_Name is not valid.')  
 GOTO ReturnResultSets  
END  
  
  
  
-------------------------------------------------------------------------------------  
-- Declare variables for this procedure  
-------------------------------------------------------------------------------------  
  
Declare   
 @PL_Id      int,  
 @Result      varchar(25),  
 @Total      float,  
 @Count      int,  
 @TNE_Conversion     float,  
 @KG_Conversion     float,  
 @Production_PU_Id    int,  
 @Quality_PU_Id     int,  
 @Rolls_PU_Id     int,  
 @Sheetbreak_PU_Id    int,  
 @Downtime_PU_Id     int,  
 @Creping_Blade_PU_Id    int,  
 @Cleaning_Blade_PU_Id    int,  
 @Materials_PU_Id    int,  
 @Forming_Wire_PU_Id    int,  
 @Backing_Wire_PU_Id    int,  
 @Belt_PU_Id     int,  
 @Quality_Testing_PUG_Id    int,  
 @Quality_QCS_PUG_Id    int,  
 @Good_Tons_Var_Id    int,  
 @Consumed_Tons_Var_Id    int,  
 @Shipped_Tons_Var_Id    int,  
 @Reject_Tons_Var_Id    int,  
 @Hold_Tons_Var_Id    int,  
 @Fire_Tons_Var_Id    int,  
 @Slab_Var_Id     int,  
 @Teardown_Var_Id    int,  
 @Repulper_Tons_Var_Id    int,  
 @TAY_Var_Id     int,  
 @RA_Var_Id     int,  
 @Valid_Tons_Limit    float,  
 @Good_Tons_Sum     float,  
 @Reject_Tons_Sum    float,  
 @Hold_Tons_Sum     float,  
 @Fire_Tons_Sum     float,  
 @Slab_Sum     float,  
 @Teardown_Sum     float,  
 @TAY_Sum     float,  
 @RA_Sum      float,  
 @Repulper_Tons_Sum    float,  
 @Good_Status_Id     int,  
 @Not_Perfect_Status_Id    int,  
 @Perfect_Status_id    int,  
 @Quarantine_Status_Id   int,  
 @Flagged_Status_Id   int,  
 @Consumed_Status_Id    int,  
 @Received_Status_Id    int,  
 @Shipped_Status_Id    int,  
 @Good_Roll_Count    int,  
 @Reject_Status_Id    int,  
 @Reject_Roll_Count    int,  
 @Hold_Status_Id     int,  
 @Hold_Roll_Count    int,  
 @Fire_Status_Id     int,  
 @Fire_Roll_Count    int,  
 @Reel_Time_Var_Id    int,  
 @Downtime_Count_Var_Id    int,  
 @Downtime_Count     int,  
 @GI_Downtime     float,  
 @GE_Downtime     float,  
 @GI_Uptime     float,  
 @GE_Uptime     float,  
 @Downtime_Invalid_Status_Id   int,  
 @Sheetbreak_Count_Var_Id   int,  
 @Sheetbreak_Count    int,  
 @Sheetbreak_Time    float,  
 @Sheetbreak_Invalid_Status_Id   int,  
 @Product_Start_Time    datetime,  
 @Product_End_Time    datetime,  
 @Prod_Id     int,  
 @Prod_Desc     varchar(50),  
 @Last_Prod_Id     int,  
 @Last_Prod_Desc     varchar(50),  
 @Product_Time     float,  
 @Cleaning_Blades    int,  
 @Creping_Blades     int,  
 @Forming_Wire_Life    float,  
 @Backing_Wire_Life    float,  
 @Belt_Life     float,  
             --**************** Speed Variables ***************  
 @Yankee_Speed_Var_Id    int,  
 @Reel_Speed_Var_Id    int,  
 @Crepe_Var_Id     int,  
 @Yankee_Speed_Count    int,  
 @Yankee_Speed_Sum    float,  
 @Reel_Speed_Count    int,  
 @Reel_Speed_Sum     float,  
 @Crepe      float,  
             --************ Line Status Variables *************  
 @LS_Data_Type_Id     int,  
 @LS_Start_Time     datetime,  
 @Line_Status_Id     int,  
 @Next_Line_Status_Id    int,  
 @GE_Run_Id     int,  
 @GE_Non_Run_Id     int,  
 @Line_Status_Fetch    int,  
 @Range_Start_Time    datetime,  
 @Range_End_Time     datetime,  
             --************** Furnish Variables ***************  
 @3rd_Furnish_Var_Id    int,  
 @CTMP_Var_Id     int,  
 @Fiber_1_Var_Id     int,  
 @Fiber_2_Var_Id     int,  
 @Long_Fiber_Var_Id    int,  
 @Machine_Broke_Var_Id    int,  
 @Product_Broke_Var_Id    int,  
 @Short_Fiber_Var_Id    int,  
 @3rd_Furnish_Sum    float,  
 @CTMP_Sum     float,  
 @Fiber_1_Sum     float,  
 @Fiber_2_Sum     float,  
 @Long_Fiber_Sum     float,  
 @Machine_Broke_Sum    float,  
 @Product_Broke_Sum    float,  
 @Short_Fiber_Sum    float,  
             --************** Chemical Variables ***************  
 @Absorb_Aid_Towel_Var_Id   int,  
 @Aloe_E_Additive_Var_Id    int,  
 @Biocide_Var_Id     int,  
 @Cat_Promoter_Var_Id    int,  
 @Chem_1_Var_Id     int,  
 @Chem_2_Var_Id     int,  
 @Chlorine_Control_Var_Id   int,  
 @Defoamer_Var_Id    int,  
 @Dry_Strength_Facial_Var_Id   int,  
 @Dry_Strength_Tissue_Var_Id   int,  
 @Dry_Strength_Towel_Var_Id   int,  
 @Dye_1_Var_Id     int,  
 @Dye_2_Var_Id     int,  
 @Emulsion_1_Var_Id    int,  
 @Emulsion_2_Var_Id    int,  
 @Flocculant_Var_Id    int,  
 @Glue_Adhesive_Var_Id    int,  
 @Glue_Crepe_Aid_Var_Id    int,  
 @Glue_Release_Aid_Var_Id   int,  
 @Glue_Total_Var_Id    int,  
 @pH_Control_Tissue_Acid_Var_Id   int,  
 @pH_Control_Towel_Base_Var_Id   int,  
 @Single_Glue_Var_Id    int,  
 @Softener_Facial_Var_Id    int,  
 @Softener_Tissue_Var_Id    int,  
 @Softener_Towel_Var_Id    int,  
 @Wet_Strength_Facial_Var_Id   int,  
 @Wet_Strength_Tissue_Var_Id   int,  
 @Wet_Strength_Towel_Var_Id   int,  
 @Absorb_Aid_Towel_Sum    float,  
 @Aloe_E_Additive_Sum    float,  
 @Biocide_Sum     float,  
 @Cat_Promoter_Sum    float,  
 @Chem_1_Sum     float,  
 @Chem_2_Sum     float,  
 @Chlorine_Control_Sum    float,  
 @Defoamer_Sum     float,  
 @Dry_Strength_Facial_Sum   float,  
 @Dry_Strength_Tissue_Sum   float,  
 @Dry_Strength_Towel_Sum    float,  
 @Dye_1_Sum     float,  
 @Dye_2_Sum     float,  
 @Emulsion_1_Sum     float,  
 @Emulsion_2_Sum     float,  
 @Flocculant_Sum     float,  
 @Glue_Adhesive_Sum    float,  
 @Glue_Crepe_Aid_Sum    float,  
 @Glue_Release_Aid_Sum    float,  
 @Glue_Total_Sum     float,  
 @pH_Control_Tissue_Acid_Sum   float,  
 @pH_Control_Towel_Base_Sum   float,  
 @Single_Glue_Sum    float,  
 @Softener_Facial_Sum    float,  
 @Softener_Tissue_Sum    float,  
 @Softener_Towel_Sum    float,  
 @Wet_Strength_Facial_Sum   float,  
 @Wet_Strength_Tissue_Sum   float,  
 @Wet_Strength_Towel_Sum    float,  
             --**************** Utility Variables *****************  
 @Air_Var_Id     int,  
 @Air_UOM     varchar(15),  
 @Electric_Var_Id    int,  
 @Electric_UOM     varchar(15),  
 @Gas_Var_Id     int,  
 @Gas_UOM     varchar(15),  
 @Steam_Var_Id     int,  
 @Steam_UOM     varchar(15),  
 @Water_Var_Id     int,  
 @Water_UOM     varchar(15),  
 @Air_Sum     float,  
 @Electric_Sum     float,  
 @Gas_Sum     float,  
 @Steam_Sum     float,  
 @Water_Sum     float,  
 --************************  Quality  ******************************  
 @Basis_Weight_Manual_Var_Id   int,  
 @Caliper_Average_Roll_A_Var_Id   int,  
 @Caliper_Average_Roll_B_Var_Id    int,  
 @Caliper_Range_Roll_A_Var_Id    int,  
 @Caliper_Range_Roll_B_Var_Id    int,  
 @Color_A_Value_Var_Id     int,  
 @Color_B_Value_Var_Id     int,  
 @Color_L_Value_Var_Id     int,  
 @Holes_Large_Measurement_Var_Id   int,  
 @Holes_Small_Count_Var_Id    int,  
 @Sink_Average_Var_Id     int,  
 @Soft_Tissue_DS_SD_AVG_Var_Id    int,  
 @Soft_Tissue_DS_WR_AVG_Var_Id    int,  
 @Soft_Tissue_TS_SD_AVG_Var_Id    int,  
 @Soft_Tissue_TS_WR_AVG_Var_Id    int,  
 @Specks_Gross_Count_Var_Id    int,  
 @Specks_Large_Count_Var_Id    int,  
 @Specks_Red_Count_Var_Id    int,  
 @Specks_Small_Count_Var_Id    int,  
 @Specks_Tiny_Count_Var_Id    int,  
 @Stretch_CD_Var_Id     int,  
 @Stretch_MD_Var_Id    int,  
 @Tensile_CD_Var_Id     int,  
 @Tensile_MD_Var_Id    int,  
 @Tensile_Modulus_CD_Var_Id    int,  
 @Tensile_Modulus_GM_Var_Id    int,  
 @Tensile_Modulus_MD_Var_Id    int,  
 @Tensile_Ratio_Var_Id     int,  
 @Tensile_Total_Var_Id     int,  
 @Wet_Burst_Average_Var_Id    int,  
 @Wet_Tensile_Average_Var_Id    int,  
 @Wet_Tensile_CD_Var_Id     int,  
 @Wet_Tensile_MD_Var_Id     int,  
 @Wet_Tensile_Ratio_Var_Id    int,  
 @Wet_Tensile_Total_Var_Id    int,  
 @Wet_Dry_Tissue_Ratio_Var_Id    int,  
 @Wet_Dry_Towel_Ratio_Var_Id    int,  
 @Basis_Weight_Manual_Count   int,  
 @Caliper_Average_Roll_A_Count   int,  
 @Caliper_Average_Roll_B_Count    int,  
 @Caliper_Range_Roll_A_Count    int,  
 @Caliper_Range_Roll_B_Count    int,  
 @Color_A_Value_Count     int,  
 @Color_B_Value_Count     int,  
 @Color_L_Value_Count     int,  
 @Holes_Large_Measurement_Count    int,  
 @Holes_Small_Count_Count    int,  
 @Sink_Average_Count     int,  
 @Soft_Tissue_DS_SD_AVG_Count    int,  
 @Soft_Tissue_DS_WR_AVG_Count    int,  
 @Soft_Tissue_TS_SD_AVG_Count    int,  
 @Soft_Tissue_TS_WR_AVG_Count    int,  
 @Specks_Gross_Count_Count    int,  
 @Specks_Large_Count_Count    int,  
 @Specks_Red_Count_Count    int,  
 @Specks_Small_Count_Count    int,  
 @Specks_Tiny_Count_Count    int,  
 @Stretch_CD_Count     int,  
 @Stretch_MD_Count    int,  
 @Tensile_CD_Count     int,  
 @Tensile_MD_Count    int,  
 @Tensile_Modulus_CD_Count    int,  
 @Tensile_Modulus_GM_Count    int,  
 @Tensile_Modulus_MD_Count    int,  
 @Tensile_Ratio_Count     int,  
 @Tensile_Total_Count     int,  
 @Wet_Burst_Average_Count    int,  
 @Wet_Tensile_Average_Count    int,  
 @Wet_Tensile_CD_Count     int,  
 @Wet_Tensile_MD_Count     int,  
 @Wet_Tensile_Ratio_Count    int,  
 @Wet_Tensile_Total_Count    int,  
 @Wet_Dry_Tissue_Ratio_Count    int,  
 @Wet_Dry_Towel_Ratio_Count    int,  
 @Basis_Weight_Manual_Sum   float,  
 @Caliper_Average_Roll_A_Sum   float,  
 @Caliper_Average_Roll_B_Sum    float,  
 @Caliper_Range_Roll_A_Sum    float,  
 @Caliper_Range_Roll_B_Sum    float,  
 @Color_A_Value_Sum     float,  
 @Color_B_Value_Sum     float,  
 @Color_L_Value_Sum     float,  
 @Holes_Large_Measurement_Sum    float,  
 @Holes_Small_Count_Sum     float,  
 @Sink_Average_Sum     float,  
 @Soft_Tissue_DS_SD_AVG_Sum    float,  
 @Soft_Tissue_DS_WR_AVG_Sum    float,  
 @Soft_Tissue_TS_SD_AVG_Sum    float,  
 @Soft_Tissue_TS_WR_AVG_Sum    float,  
 @Specks_Gross_Count_Sum    float,  
 @Specks_Large_Count_Sum    float,  
 @Specks_Red_Count_Sum     float,  
 @Specks_Small_Count_Sum    float,  
 @Specks_Tiny_Count_Sum     float,  
 @Stretch_CD_Sum     float,  
 @Stretch_MD_Sum     float,  
 @Tensile_CD_Sum     float,  
 @Tensile_MD_Sum     float,  
 @Tensile_Modulus_CD_Sum    float,  
 @Tensile_Modulus_GM_Sum    float,  
 @Tensile_Modulus_MD_Sum    float,  
 @Tensile_Ratio_Sum     float,  
 @Tensile_Total_Sum     float,  
 @Wet_Burst_Average_Sum     float,  
 @Wet_Tensile_Average_Sum    float,  
 @Wet_Tensile_CD_Sum     float,  
 @Wet_Tensile_MD_Sum     float,  
 @Wet_Tensile_Ratio_Sum     float,  
 @Wet_Tensile_Total_Sum     float,  
 @Wet_Dry_Tissue_Ratio_Sum    float,  
 @Wet_Dry_Towel_Ratio_Sum    float  
 /* Get Materials (Chemicals + Furnish + Water + Energy) */  
  
Select @Time1 = getdate()  
  
/************************************************************************************************  
*                                                                                                                               *  
*                                     Initialization                                                               *  
*                                                                                                                               *  
************************************************************************************************/  
Select    
 @Valid_Tons_Limit    = 0.0,  
 @TNE_Conversion     = convert(float,@RptConvertTNE), --1.102311,  
 @KG_Conversion     = convert(float,@RptConvertKG),--2.2046,  
 @Product_Time     = Null,  
 @Good_Tons_Sum      = Null,  
 @Reject_Tons_Sum     = Null,  
 @Hold_Tons_Sum      = Null,  
 @Fire_Tons_Sum      = Null,  
 @Slab_Sum     = Null,  
 @Teardown_Sum     = Null,  
 @Repulper_Tons_Sum     = Null,  
 @TAY_Sum     = Null,  
 @RA_Sum      = Null,  
 @Sheetbreak_Time    = Null,  
 @GI_Downtime     = Null,  
 @GI_Uptime     = Null,  
 @GE_Downtime     = Null,  
 @GE_Uptime     = Null,  
 @Downtime_Count     = Null,  
 @Cleaning_Blades    = Null,  
 @Creping_Blades     = Null,  
 @Good_Roll_Count     = Null,  
 @Reject_Roll_Count     = Null,  
 @Hold_Roll_Count    = Null,  
 @Fire_Roll_Count    = Null,  
 @Sheetbreak_Count     = Null,  
 @Forming_Wire_Life    = Null,  
 @Backing_Wire_Life    = Null,  
 @Belt_Life     = Null,  
 @Reel_Speed_Count    = Null,  
 @Reel_Speed_Sum     = Null,  
 @Yankee_Speed_Count    = Null,  
 @Yankee_Speed_Sum    = Null,  
 @Crepe      = Null,  
 @3rd_Furnish_Sum     = Null,  
 @Absorb_Aid_Towel_Sum     = Null,  
 @Aloe_E_Additive_Sum     = Null,  
 @Biocide_Sum      = Null,  
 @Cat_Promoter_Sum     = Null,  
 @Chem_1_Sum      = Null,  
 @Chem_2_Sum      = Null,  
 @Chlorine_Control_Sum     = Null,  
 @CTMP_Sum      = Null,  
 @Defoamer_Sum      = Null,  
 @Dry_Strength_Facial_Sum   = Null,  
 @Dry_Strength_Tissue_Sum   = Null,  
 @Dry_Strength_Towel_Sum    = Null,  
 @Dye_1_Sum      = Null,  
 @Dye_2_Sum      = Null,  
 @Emulsion_1_Sum     = Null,  
 @Emulsion_2_Sum     = Null,  
 @Fiber_1_Sum      = Null,  
 @Fiber_2_Sum      = Null,  
 @Flocculant_Sum     = Null,  
 @Glue_Adhesive_Sum     = Null,  
 @Glue_Crepe_Aid_Sum     = Null,  
 @Glue_Release_Aid_Sum     = Null,  
 @Glue_Total_Sum     = Null,  
 @Long_Fiber_Sum     = Null,  
 @Machine_Broke_Sum     = Null,  
 @pH_Control_Tissue_Acid_Sum    = Null,  
 @pH_Control_Towel_Base_Sum    = Null,  
 @Product_Broke_Sum     = Null,  
 @Short_Fiber_Sum     = Null,  
 @Single_Glue_Sum     = Null,  
 @Softener_Facial_Sum    = Null,  
 @Softener_Tissue_Sum    = Null,  
 @Softener_Towel_Sum    = Null,  
 @Wet_Strength_Facial_Sum   = Null,  
 @Wet_Strength_Tissue_Sum   = Null,  
 @Wet_Strength_Towel_Sum    = Null,  
 @Air_Sum     = Null,  
 @Electric_Sum     = Null,  
 @Electric_UOM     = Null,  
 @Gas_Sum     = Null,  
 @Gas_UOM     = Null,  
 @Steam_Sum     = Null,  
 @Steam_UOM     = Null,  
 @Water_Sum     = Null,  
 @Water_UOM     = Null  
  
-- *** Adjust End Time to current time if it's greater (CE 5/22/02) ***  
  
If @Report_End_Time > getdate() set @Report_End_Time = getdate()  
  
/************************************************************************************************  
*                                                                                                                               *  
*                                     Get Configuration                                                               *  
*                                                                                                                               *  
************************************************************************************************/  
/* Get the line id */  
Select @PL_Id = PL_Id  
From Prod_Lines  
Where PL_Desc = 'TT ' + ltrim(rtrim(@Line_Name))  
  
/* Get Different PU Ids */  
Select @Production_PU_Id = PU_Id  
From Prod_Units  
Where PL_Id = @PL_Id And PU_Desc = @Line_Name + ' Production'  
  
Select @Quality_PU_Id = PU_Id  
From Prod_Units  
Where PL_Id = @PL_Id And PU_Desc = @Line_Name + ' Turnover Quality'  
  
Select @Rolls_PU_Id = PU_Id  
From Prod_Units  
Where PL_Id = @PL_Id And PU_Desc = @Line_Name + ' Rolls'  
  
Select @Sheetbreak_PU_Id = PU_Id  
From Prod_Units  
Where PL_Id = @PL_Id And PU_Desc = @Line_Name + ' Sheetbreak'  
  
Select @Downtime_PU_Id = PU_Id  
From Prod_Units  
Where PL_Id = @PL_Id And PU_Desc = @Line_Name + ' Reliability'  
  
Select @Creping_Blade_PU_Id = PU_Id  
From Prod_Units  
Where PL_Id = @PL_Id And PU_Desc = @Line_Name + ' Creping Blade'  
  
Select @Cleaning_Blade_PU_Id = PU_Id  
From Prod_Units  
Where PL_Id = @PL_Id And PU_Desc = @Line_Name + ' Cleaning Blade'  
  
Select @Materials_PU_Id = PU_Id  
From Prod_Units  
Where PL_Id = @PL_Id And PU_Desc = @Line_Name + ' Materials'  
  
Select @Forming_Wire_PU_Id = PU_Id  
From Prod_Units  
Where PL_Id = @PL_Id And PU_Desc = @Line_Name + ' Forming Wire'  
  
Select @Backing_Wire_PU_Id = PU_Id  
From Prod_Units  
Where PL_Id = @PL_Id And PU_Desc = @Line_Name + ' Backing Wire'  
  
Select @Belt_PU_Id = PU_Id  
From Prod_Units  
Where PL_Id = @PL_Id And PU_Desc = @Line_Name + ' Belt'  
  
/* Get statuses */  
--Select @Good_Status_Id = ProdStatus_Id   From Production_Status Where ProdStatus_Desc = 'Good'  
Select @Not_Perfect_Status_Id = ProdStatus_Id   From Production_Status Where (ProdStatus_Desc = 'Not Perfect') or (ProdStatus_Desc ='Good') --NHK 22 Nov 2005  
  
Select @Perfect_Status_Id = ProdStatus_Id   From Production_Status Where ProdStatus_Desc = 'Perfect'  
--Select @Quarantine_Status_Id = ProdStatus_Id   From Production_Status Where ProdStatus_Desc = 'Quarantine'  
Select @Flagged_Status_Id = ProdStatus_Id   From Production_Status Where (ProdStatus_Desc = 'Flagged') or (ProdStatus_Desc = 'Quarantine')--NHK 22 Nov 2005  
  
Select @Shipped_Status_Id = ProdStatus_Id  From Production_Status Where ProdStatus_Desc = 'Shipped'  
Select @Consumed_Status_Id = ProdStatus_Id  From Production_Status Where ProdStatus_Desc = 'Consumed'  
Select @Received_Status_Id = ProdStatus_Id  From Production_Status Where ProdStatus_Desc = 'Received'  
Select @Reject_Status_Id = ProdStatus_Id  From Production_Status Where ProdStatus_Desc = 'Reject'  
Select @Hold_Status_Id = ProdStatus_Id   From Production_Status Where ProdStatus_Desc = 'Hold'  
Select @Fire_Status_Id = ProdStatus_Id   From Production_Status Where ProdStatus_Desc = 'Fire'  
  
/* Get tonnage variables */  
Select @Good_Tons_Var_Id = Var_Id  
From Variables  
Where charindex(lower('GlblDesc=Tons Released By Time;'),lower(coalesce(extended_info,''))) > 0   
And PU_Id = @Production_PU_Id  
  
Select @Consumed_Tons_Var_Id = Var_Id  
From Variables  
Where charindex(lower('GlblDesc=Tons Consumed By Time;'),lower(coalesce(extended_info,''))) > 0   
And PU_Id = @Production_PU_Id  
  
Select @Shipped_Tons_Var_Id = Var_Id  
From Variables  
Where charindex(lower('GlblDesc=Tons Shipped By Time;'),lower(coalesce(extended_info,''))) > 0   
And PU_Id = @Production_PU_Id  
  
Select @Reject_Tons_Var_Id = Var_Id  
From Variables  
Where charindex(lower('GlblDesc=Tons Reject By Time;'),lower(coalesce(extended_info,''))) > 0   
And PU_Id = @Production_PU_Id  
  
Select @Hold_Tons_Var_Id = Var_Id  
From Variables  
Where charindex(lower('GlblDesc=Tons Hold By Time;'),lower(coalesce(extended_info,''))) > 0   
And PU_Id = @Production_PU_Id  
  
Select @Fire_Tons_Var_Id = Var_Id  
From Variables  
Where charindex(lower('GlblDesc=Tons Fire By Time;'),lower(coalesce(extended_info,''))) > 0   
And PU_Id = @Production_PU_Id  
  
Select @Slab_Var_Id = Var_Id  
From Variables  
Where charindex(lower('GlblDesc=Tons Slab By Time;'),lower(coalesce(extended_info,''))) > 0   
And PU_Id = @Production_PU_Id  
  
Select @Teardown_Var_Id = Var_Id  
From Variables  
Where charindex(lower('GlblDesc=Tons Teardown By Time;'),lower(coalesce(extended_info,''))) > 0   
And PU_Id = @Production_PU_Id  
  
Select @Repulper_Tons_Var_Id = Var_Id  
From Variables  
Where charindex(lower('GlblDesc=Tons Repulper By Time;'),lower(coalesce(extended_info,''))) > 0   
And PU_Id = @Sheetbreak_PU_Id  
  
Select @TAY_Var_Id = Var_Id  
From Variables  
Where charindex(lower('GlblDesc=Production Rate Hr Sum;'),lower(coalesce(extended_info,''))) > 0   
And PU_Id = @Production_PU_Id  
  
Select @RA_Var_Id = Var_Id  
From Variables  
Where charindex(lower('GlblDesc=Reel Additive Hr Sum;'),lower(coalesce(extended_info,''))) > 0   
And PU_Id = @Production_PU_Id  
  
/* Get reliability configuration */  
Select @Sheetbreak_Count_Var_Id = Var_Id  
From Variables  
Where charindex(lower('GlblDesc=Sheetbreak Primary;'),lower(coalesce(extended_info,''))) > 0   
And PU_Id = @Sheetbreak_PU_Id  
  
Select @Reel_Time_Var_Id = Var_Id  
From Variables  
Where charindex(lower('GlblDesc=Sheet Reel Time;'),lower(coalesce(extended_info,''))) > 0   
And PU_Id = @Sheetbreak_PU_Id  
  
Select @Downtime_Count_Var_Id = Var_Id  
From Variables  
Where charindex(lower('GlblDesc=Downtime Primary;'),lower(coalesce(extended_info,''))) > 0   
And PU_Id = @Downtime_PU_Id  
  
Select @Downtime_Invalid_Status_Id = TEStatus_Id  
From Timed_Event_Status  
Where PU_Id = @Downtime_PU_Id And TEStatus_Name = 'Invalid'  
  
Select @Sheetbreak_Invalid_Status_Id = TEStatus_Id  
From Timed_Event_Status  
Where PU_Id = @Sheetbreak_PU_Id And TEStatus_Name = 'Invalid'  
  
/* Get quality variables */  
Select @Quality_Testing_PUG_Id = PUG_Id  
From PU_Groups  
Where PU_ID = @Quality_PU_Id And PUG_Desc = 'Turnover Testing'  
  
Select @Quality_QCS_PUG_Id = PUG_Id  
From PU_Groups  
Where PU_ID = @Quality_PU_Id And PUG_Desc = 'QCS'  
  
/* Get line status configuration variables */  
Select @LS_Data_Type_Id = Data_Type_Id  
From Data_Type  
Where Data_Type_Desc = 'Line Status'  
  
Select @GE_Run_Id = Phrase_Id  
From Phrase  
Where Data_Type_Id = @LS_Data_Type_Id And Phrase_Value = 'Run - Global Excluded'  
  
Select @GE_Non_Run_Id = Phrase_Id  
From Phrase  
Where Data_Type_Id = @LS_Data_Type_Id And Phrase_Value = 'Non-run - Global Excluded'  
  
/* Get speed variables */  
Select @Yankee_Speed_Var_Id = Var_Id  
From Variables  
Where charindex(lower('GlblDesc=Yankee Speed Hr Avg;'),lower(coalesce(extended_info,''))) > 0   
And PU_Id = @Production_PU_Id  
  
Select @Reel_Speed_Var_Id = Var_Id  
From Variables  
Where charindex(lower('GlblDesc=Reel Speed Hr Avg;'),lower(coalesce(extended_info,''))) > 0   
And PU_Id = @Production_PU_Id  
  
/* Get chemical variables */  
Select @3rd_Furnish_Var_Id = Var_Id From Variables Where PU_Id = @Materials_PU_Id   
and charindex(lower('GlblDesc=3rd Furnish Dry Flow Hr Sum;'),lower(coalesce(extended_info,''))) > 0   
  
Select @CTMP_Var_Id = Var_Id From Variables Where PU_Id = @Materials_PU_Id   
and charindex(lower('GlblDesc=CTMP Dry Flow Hr Sum;'),lower(coalesce(extended_info,''))) > 0   
  
Select @Fiber_1_Var_Id = Var_Id From Variables Where PU_Id = @Materials_PU_Id   
and charindex(lower('GlblDesc=Fiber 1 Dry Flow Hr Sum;'),lower(coalesce(extended_info,''))) > 0   
  
Select @Fiber_2_Var_Id = Var_Id From Variables Where PU_Id = @Materials_PU_Id   
and charindex(lower('GlblDesc=Fiber 2 Dry Flow Hr Sum;'),lower(coalesce(extended_info,''))) > 0   
  
Select @Long_Fiber_Var_Id = Var_Id From Variables Where PU_Id = @Materials_PU_Id   
and charindex(lower('GlblDesc=Long Fiber Dry Flow Hr Sum;'),lower(coalesce(extended_info,''))) > 0   
  
Select @Machine_Broke_Var_Id = Var_Id From Variables Where PU_Id = @Materials_PU_Id   
and charindex(lower('GlblDesc=Machine Broke Dry Flow Hr Sum;'),lower(coalesce(extended_info,''))) > 0   
  
Select @Product_Broke_Var_Id = Var_Id From Variables Where PU_Id = @Materials_PU_Id   
and charindex(lower('GlblDesc=Product Broke Dry Flow Hr Sum;'),lower(coalesce(extended_info,''))) > 0   
  
Select @Short_Fiber_Var_Id = Var_Id From Variables Where PU_Id = @Materials_PU_Id   
and charindex(lower('GlblDesc=Short Fiber Dry Flow Hr Sum;'),lower(coalesce(extended_info,''))) > 0   
  
Select @Absorb_Aid_Towel_Var_Id = Var_Id From Variables Where PU_Id = @Materials_PU_Id   
and charindex(lower('GlblDesc=Absorb Aid Towel Mass Flow Hr Sum;'),lower(coalesce(extended_info,''))) > 0   
  
Select @Aloe_E_Additive_Var_Id = Var_Id From Variables Where PU_Id = @Materials_PU_Id   
and charindex(lower('GlblDesc=Aloe_E Additive Mass Flow Hr Sum;'),lower(coalesce(extended_info,''))) > 0   
  
Select @Biocide_Var_Id = Var_Id From Variables Where PU_Id = @Materials_PU_Id   
and charindex(lower('GlblDesc=Biocide Mass Flow Hr Sum;'),lower(coalesce(extended_info,''))) > 0   
  
Select @Cat_Promoter_Var_Id = Var_Id From Variables Where PU_Id = @Materials_PU_Id   
and charindex(lower('GlblDesc=Cat Promoter Mass Flow Hr Sum;'),lower(coalesce(extended_info,''))) > 0   
  
Select @Chem_1_Var_Id = Var_Id From Variables Where PU_Id = @Materials_PU_Id   
and charindex(lower('GlblDesc=Chem 1 Mass Flow Hr Sum;'),lower(coalesce(extended_info,''))) > 0   
  
Select @Chem_2_Var_Id = Var_Id From Variables Where PU_Id = @Materials_PU_Id   
and charindex(lower('GlblDesc=Chem 2 Mass Flow Hr Sum;'),lower(coalesce(extended_info,''))) > 0   
  
Select @Chlorine_Control_Var_Id = Var_Id From Variables Where PU_Id = @Materials_PU_Id   
and charindex(lower('GlblDesc=Chlorine Control Mass Flow Hr Sum;'),lower(coalesce(extended_info,''))) > 0   
  
Select @Defoamer_Var_Id = Var_Id From Variables Where PU_Id = @Materials_PU_Id   
and charindex(lower('GlblDesc=Defoamer Mass Flow Hr Sum;'),lower(coalesce(extended_info,''))) > 0   
  
Select @Dry_Strength_Facial_Var_Id = Var_Id From Variables Where PU_Id = @Materials_PU_Id   
and charindex(lower('GlblDesc=Dry Strength Facial Mass Flow Hr Sum;'),lower(coalesce(extended_info,''))) > 0   
  
Select @Dry_Strength_Tissue_Var_Id = Var_Id From Variables Where PU_Id = @Materials_PU_Id   
and charindex(lower('GlblDesc=Dry Strength Tissue Mass Flow Hr Sum;'),lower(coalesce(extended_info,''))) > 0   
  
Select @Dry_Strength_Towel_Var_Id = Var_Id From Variables Where PU_Id = @Materials_PU_Id   
and charindex(lower('GlblDesc=Dry Strength Towel Mass Flow Hr Sum;'),lower(coalesce(extended_info,''))) > 0   
  
Select @Dye_1_Var_Id = Var_Id From Variables Where PU_Id = @Materials_PU_Id   
and charindex(lower('GlblDesc=Dye 1 Mass Flow Hr Sum;'),lower(coalesce(extended_info,''))) > 0   
  
Select @Dye_2_Var_Id = Var_Id From Variables Where PU_Id = @Materials_PU_Id   
and charindex(lower('GlblDesc=Dye 2 Mass Flow Hr Sum;'),lower(coalesce(extended_info,''))) > 0   
  
Select @Emulsion_1_Var_Id = Var_Id From Variables Where PU_Id = @Materials_PU_Id   
and charindex(lower('GlblDesc=Emulsion 1 Mass Flow Hr Sum;'),lower(coalesce(extended_info,''))) > 0   
  
Select @Emulsion_2_Var_Id = Var_Id From Variables Where PU_Id = @Materials_PU_Id   
and charindex(lower('GlblDesc=Emulsion 2 Mass Flow Hr Sum;'),lower(coalesce(extended_info,''))) > 0   
  
Select @Flocculant_Var_Id = Var_Id From Variables Where PU_Id = @Materials_PU_Id   
and charindex(lower('GlblDesc=Flocculant Mass Flow Hr Sum;'),lower(coalesce(extended_info,''))) > 0   
  
Select @Glue_Adhesive_Var_Id = Var_Id From Variables Where PU_Id = @Materials_PU_Id   
and charindex(lower('GlblDesc=Glue Adhesive Mass Flow Hr Sum;'),lower(coalesce(extended_info,''))) > 0   
  
Select @Glue_Crepe_Aid_Var_Id = Var_Id From Variables Where PU_Id = @Materials_PU_Id   
and charindex(lower('GlblDesc=Glue Crepe Aid Mass Flow Hr Sum;'),lower(coalesce(extended_info,''))) > 0   
  
Select @Glue_Release_Aid_Var_Id = Var_Id From Variables Where PU_Id = @Materials_PU_Id   
and charindex(lower('GlblDesc=Glue Release Aid Mass Flow Hr Sum;'),lower(coalesce(extended_info,''))) > 0   
  
Select @Glue_Total_Var_Id = Var_Id From Variables Where PU_Id = @Materials_PU_Id   
and charindex(lower('GlblDesc=Glue Total Mass Flow Hr Sum;'),lower(coalesce(extended_info,''))) > 0   
  
Select @pH_Control_Tissue_Acid_Var_Id = Var_Id From Variables Where PU_Id = @Materials_PU_Id   
and charindex(lower('GlblDesc=pH Control Tissue Acid Mass Flow Hr Sum;'),lower(coalesce(extended_info,''))) > 0   
  
Select @pH_Control_Towel_Base_Var_Id = Var_Id From Variables Where PU_Id = @Materials_PU_Id   
and charindex(lower('GlblDesc=pH Control Towel Base Mass Flow Hr Sum;'),lower(coalesce(extended_info,''))) > 0   
  
Select @Single_Glue_Var_Id = Var_Id From Variables Where PU_Id = @Materials_PU_Id   
and charindex(lower('GlblDesc=Single Glue Mass Flow Hr Sum;'),lower(coalesce(extended_info,''))) > 0   
  
Select @Softener_Facial_Var_Id = Var_Id From Variables Where PU_Id = @Materials_PU_Id   
and charindex(lower('GlblDesc=Softener Facial Mass Flow Hr Sum;'),lower(coalesce(extended_info,''))) > 0   
  
Select @Softener_Tissue_Var_Id = Var_Id From Variables Where PU_Id = @Materials_PU_Id   
and charindex(lower('GlblDesc=Softener Tissue Mass Flow Hr Sum;'),lower(coalesce(extended_info,''))) > 0   
  
Select @Softener_Towel_Var_Id = Var_Id From Variables Where PU_Id = @Materials_PU_Id   
and charindex(lower('GlblDesc=Softener Towel Mass Flow Hr Sum;'),lower(coalesce(extended_info,''))) > 0   
  
Select @Wet_Strength_Facial_Var_Id = Var_Id From Variables Where PU_Id = @Materials_PU_Id   
and charindex(lower('GlblDesc=Wet Strength Facial Mass Flow Hr Sum;'),lower(coalesce(extended_info,''))) > 0   
  
Select @Wet_Strength_Tissue_Var_Id = Var_Id From Variables Where PU_Id = @Materials_PU_Id   
and charindex(lower('GlblDesc=Wet Strength Tissue Mass Flow Hr Sum;'),lower(coalesce(extended_info,''))) > 0   
  
Select @Wet_Strength_Towel_Var_Id = Var_Id From Variables Where PU_Id = @Materials_PU_Id   
and charindex(lower('GlblDesc=Wet Strength Towel Mass Flow Hr Sum;'),lower(coalesce(extended_info,''))) > 0   
  
  
/* Get utility variables */  
Select @Air_Var_Id = Var_Id From Variables Where PU_Id = @Materials_PU_Id   
and charindex(lower('GlblDesc=Turbine Air Mass Flow Hr Sum;'),lower(coalesce(extended_info,''))) > 0   
  
Select @Air_UOM = Eng_Units From Variables Where Var_Id = @Air_Var_Id  
  
Select @Electric_Var_Id = Var_Id From Variables Where PU_Id = @Materials_PU_Id   
and charindex(lower('GlblDesc=Electrical Usage Hr Sum;'),lower(coalesce(extended_info,''))) > 0   
  
Select @Electric_UOM = Eng_Units From Variables Where Var_Id = @Electric_Var_Id  
  
Select @Gas_Var_Id = Var_Id From Variables Where PU_Id = @Materials_PU_Id   
and charindex(lower('GlblDesc=Gas Usage Hr Sum;'),lower(coalesce(extended_info,''))) > 0   
  
Select @Gas_UOM = Eng_Units From Variables Where Var_Id = @Gas_Var_Id  
  
If @Line_Name = 'MP1M'   
 Select @Steam_Var_Id = Var_Id From Variables   
 Where PU_Id = @Materials_PU_Id   
 and charindex(lower('GlblDesc=HP Steam 1 Mass Flow In Hr Sum;'),  
  lower(coalesce(extended_info,''))) > 0  
Else If @Line_Name IN ('MP2M','MP3M','MP3M','MP4M','MP5M','MP6M','MP7M','MP8M','GP05','GP06')   
 Select @Steam_Var_Id = Var_Id From Variables   
 Where PU_Id = @Materials_PU_Id   
 and charindex(lower('GlblDesc=Steam Mass Flow Hr Sum;'),  
  lower(coalesce(extended_info,''))) > 0  
Else  Select @Steam_Var_Id = Var_Id From Variables   
 Where PU_Id = @Materials_PU_Id   
 and charindex(lower('GlblDesc=Steam Usage Hr Sum;'),  
   lower(coalesce(extended_info,''))) > 0   
  
Select @Steam_UOM = Eng_Units From Variables Where Var_Id = @Steam_Var_Id  
  
Select @Water_Var_Id = Var_Id From Variables Where PU_Id = @Materials_PU_Id   
and charindex(lower('GlblDesc=Water Usage Hr Sum;'),lower(coalesce(extended_info,''))) > 0   
  
Select @Water_UOM = Eng_Units From Variables Where Var_Id = @Water_Var_Id  
  
/* Get quality variables */  
Select @Basis_Weight_Manual_Var_Id = Var_Id From Variables Where PU_Id = @Quality_PU_Id   
and charindex(lower('GlblDesc=Basis Weight Manual;'),lower(coalesce(extended_info,''))) > 0  
  
Select @Caliper_Average_Roll_A_Var_Id = Var_Id From Variables Where PU_Id = @Quality_PU_Id   
and charindex(lower('GlblDesc=Caliper Average Roll A;'),lower(coalesce(extended_info,''))) > 0  
  
Select @Caliper_Average_Roll_B_Var_Id = Var_Id From Variables Where PU_Id = @Quality_PU_Id   
and charindex(lower('GlblDesc=Caliper Average Roll B;'),lower(coalesce(extended_info,''))) > 0  
  
Select @Caliper_Range_Roll_A_Var_Id = Var_Id From Variables Where PU_Id = @Quality_PU_Id   
and charindex(lower('GlblDesc=Caliper Range Roll A;'),lower(coalesce(extended_info,''))) > 0  
  
Select @Caliper_Range_Roll_B_Var_Id = Var_Id From Variables Where PU_Id = @Quality_PU_Id   
and charindex(lower('GlblDesc=Caliper Range Roll B;'),lower(coalesce(extended_info,''))) > 0  
  
Select @Color_A_Value_Var_Id = Var_Id From Variables Where PU_Id = @Quality_PU_Id   
and charindex(lower('GlblDesc=Color A Value;'),lower(coalesce(extended_info,''))) > 0  
  
Select @Color_B_Value_Var_Id = Var_Id From Variables Where PU_Id = @Quality_PU_Id   
and charindex(lower('GlblDesc=Color B Value;'),lower(coalesce(extended_info,''))) > 0  
  
Select @Color_L_Value_Var_Id = Var_Id From Variables Where PU_Id = @Quality_PU_Id   
and charindex(lower('GlblDesc=Color L Value;'),lower(coalesce(extended_info,''))) > 0  
  
Select @Holes_Large_Measurement_Var_Id = Var_Id From Variables Where PU_Id = @Quality_PU_Id   
and charindex(lower('GlblDesc=Holes Large Measurement;'),lower(coalesce(extended_info,''))) > 0  
  
Select @Holes_Small_Count_Var_Id = Var_Id From Variables Where PU_Id = @Quality_PU_Id   
and charindex(lower('GlblDesc=Holes Small Count;'),lower(coalesce(extended_info,''))) > 0  
  
Select @Sink_Average_Var_Id = Var_Id From Variables Where PU_Id = @Quality_PU_Id   
and charindex(lower('GlblDesc=Sink Average;'),lower(coalesce(extended_info,''))) > 0  
  
Select @Soft_Tissue_DS_SD_AVG_Var_Id = Var_Id From Variables Where PU_Id = @Quality_PU_Id   
and charindex(lower('GlblDesc=Softener Tissue DS SD/AVG;'),lower(coalesce(extended_info,''))) > 0  
  
Select @Soft_Tissue_DS_WR_AVG_Var_Id = Var_Id From Variables Where PU_Id = @Quality_PU_Id   
and charindex(lower('GlblDesc=Softener Tissue DS WR/AVG;'),lower(coalesce(extended_info,''))) > 0  
  
Select @Soft_Tissue_TS_SD_AVG_Var_Id = Var_Id From Variables Where PU_Id = @Quality_PU_Id   
and charindex(lower('GlblDesc=Softener Tissue TS SD/AVG;'),lower(coalesce(extended_info,''))) > 0  
  
Select @Soft_Tissue_TS_WR_AVG_Var_Id = Var_Id From Variables Where PU_Id = @Quality_PU_Id   
and charindex(lower('GlblDesc=Softener Tissue TS WR/AVG;'),lower(coalesce(extended_info,''))) > 0  
  
Select @Specks_Gross_Count_Var_Id = Var_Id From Variables Where PU_Id = @Quality_PU_Id   
and charindex(lower('GlblDesc=Specks Gross Count;'),lower(coalesce(extended_info,''))) > 0  
  
Select @Specks_Large_Count_Var_Id = Var_Id From Variables Where PU_Id = @Quality_PU_Id   
and charindex(lower('GlblDesc=Specks Large Count;'),lower(coalesce(extended_info,''))) > 0  
  
Select @Specks_Red_Count_Var_Id = Var_Id From Variables Where PU_Id = @Quality_PU_Id   
and charindex(lower('GlblDesc=Specks Red Count;'),lower(coalesce(extended_info,''))) > 0  
  
Select @Specks_Small_Count_Var_Id = Var_Id From Variables Where PU_Id = @Quality_PU_Id   
and charindex(lower('GlblDesc=Specks Small Count;'),lower(coalesce(extended_info,''))) > 0  
  
Select @Specks_Tiny_Count_Var_Id = Var_Id From Variables Where PU_Id = @Quality_PU_Id   
and charindex(lower('GlblDesc=Specks Tiny Count;'),lower(coalesce(extended_info,''))) > 0  
  
Select @Stretch_CD_Var_Id = Var_Id From Variables Where PU_Id = @Quality_PU_Id   
and charindex(lower('GlblDesc=Stretch CD;'),lower(coalesce(extended_info,''))) > 0  
  
Select @Stretch_MD_Var_Id = Var_Id From Variables Where PU_Id = @Quality_PU_Id   
and charindex(lower('GlblDesc=Stretch MD;'),lower(coalesce(extended_info,''))) > 0  
  
Select @Tensile_CD_Var_Id = Var_Id From Variables Where PU_Id = @Quality_PU_Id   
and charindex(lower('GlblDesc=Tensile CD;'),lower(coalesce(extended_info,''))) > 0  
  
Select @Tensile_MD_Var_Id = Var_Id From Variables Where PU_Id = @Quality_PU_Id   
and charindex(lower('GlblDesc=Tensile MD;'),lower(coalesce(extended_info,''))) > 0  
  
Select @Tensile_Modulus_CD_Var_Id = Var_Id From Variables Where PU_Id = @Quality_PU_Id   
and charindex(lower('GlblDesc=Tensile Modulus CD;'),lower(coalesce(extended_info,''))) > 0  
  
Select @Tensile_Modulus_GM_Var_Id = Var_Id From Variables Where PU_Id = @Quality_PU_Id   
and charindex(lower('GlblDesc=Tensile Modulus GM;'),lower(coalesce(extended_info,''))) > 0  
  
Select @Tensile_Modulus_MD_Var_Id = Var_Id From Variables Where PU_Id = @Quality_PU_Id   
and charindex(lower('GlblDesc=Tensile Modulus MD;'),lower(coalesce(extended_info,''))) > 0  
  
Select @Tensile_Ratio_Var_Id = Var_Id From Variables Where PU_Id = @Quality_PU_Id   
and charindex(lower('GlblDesc=Tensile Ratio;'),lower(coalesce(extended_info,''))) > 0  
  
Select @Tensile_Total_Var_Id = Var_Id From Variables Where PU_Id = @Quality_PU_Id   
and charindex(lower('GlblDesc=Tensile Total;'),lower(coalesce(extended_info,''))) > 0  
  
Select @Wet_Burst_Average_Var_Id = Var_Id From Variables Where PU_Id = @Quality_PU_Id   
and charindex(lower('GlblDesc=Wet Burst Average;'),lower(coalesce(extended_info,''))) > 0  
  
Select @Wet_Tensile_Average_Var_Id = Var_Id From Variables Where PU_Id = @Quality_PU_Id   
and charindex(lower('GlblDesc=Wet Tensile Average;'),lower(coalesce(extended_info,''))) > 0  
  
Select @Wet_Tensile_CD_Var_Id = Var_Id From Variables Where PU_Id = @Quality_PU_Id   
and charindex(lower('GlblDesc=Wet Tensile CD;'),lower(coalesce(extended_info,''))) > 0  
  
Select @Wet_Tensile_MD_Var_Id = Var_Id From Variables Where PU_Id = @Quality_PU_Id   
and charindex(lower('GlblDesc=Wet Tensile MD;'),lower(coalesce(extended_info,''))) > 0  
  
Select @Wet_Tensile_Ratio_Var_Id = Var_Id From Variables Where PU_Id = @Quality_PU_Id   
and charindex(lower('GlblDesc=Wet Tensile Ratio;'),lower(coalesce(extended_info,''))) > 0  
  
Select @Wet_Tensile_Total_Var_Id = Var_Id From Variables Where PU_Id = @Quality_PU_Id   
and charindex(lower('GlblDesc=Wet Tensile Total;'),lower(coalesce(extended_info,''))) > 0  
  
Select @Wet_Dry_Tissue_Ratio_Var_Id = Var_Id From Variables Where PU_Id = @Quality_PU_Id   
and charindex(lower('GlblDesc=Wet/Dry Tissue Ratio;'),lower(coalesce(extended_info,''))) > 0  
  
Select @Wet_Dry_Towel_Ratio_Var_Id = Var_Id From Variables Where PU_Id = @Quality_PU_Id   
and charindex(lower('GlblDesc=Wet/Dry Towel Ratio;'),lower(coalesce(extended_info,''))) > 0  
  
  
/************************************************************************************************  
*                                                                                                                               *  
*                                     Get Production Statistics                                                   *  
*                                                                                                                               *  
************************************************************************************************/  
     Declare ProductRuns Cursor Scroll For  
     Select  ps.Prod_Id,   
  p.Prod_Desc,   
  Case  When @Report_Start_Time > ps.Start_Time Then @Report_Start_Time  
   Else ps.Start_Time  
   End As Start_Time,   
  Case  When @Report_End_Time < ps.End_Time Or ps.End_Time Is Null Then @Report_End_Time  
   Else ps.End_Time  
   End As End_Time  
     From Production_Starts ps  
          Inner Join Products p On ps.Prod_Id = p.Prod_Id  
     Where PU_Id = @Production_PU_Id And  
                ps.Start_Time < @Report_End_Time And (ps.End_Time > @Report_Start_Time Or ps.End_Time Is Null)  
     Order By p.Prod_Desc Asc, Start_Time Asc  
     For Read Only  
  
  
Open ProductRuns  
  
Select @Time2 = getdate()  
       
     Fetch First From ProductRuns Into @Prod_Id, @Prod_Desc, @Product_Start_Time, @Product_End_Time  
     Select  @Last_Prod_Id   = @Prod_Id,  
  @Last_Prod_Desc = @Prod_Desc  
  
     While @@FETCH_STATUS = 0  
          Begin  
          /* Product Time */  
          Select @Product_Time = IsNull(@Product_Time, 0) + convert(float, datediff(s, @Product_Start_Time, @Product_End_Time))/60  
  
          /************************************************************************************************  
          *                                        Production Tonnage/Counts                                          *  
          ************************************************************************************************/  
          /* Good Rolls */  
          Select @Count = count(Event_Id)  
          From Events  
          Where PU_Id = @Rolls_PU_Id AND   
  TimeStamp > @Product_Start_Time AND   
  TimeStamp <= @Product_End_Time AND   
  (  
   Event_Status = @Good_Status_Id   
  OR Event_Status = @Not_Perfect_Status_Id  --NHK Added Oct18  
  OR Event_Status = @Perfect_Status_Id   
  OR Event_Status = @Quarantine_Status_Id   
  OR Event_Status = @Flagged_Status_Id  --NHK Added Oct18  
  OR Event_Status = @Consumed_Status_Id   
  OR Event_Status = @Received_Status_Id   
  OR Event_Status = @Shipped_Status_Id  
  )  
  
          Select @Total = sum(cast(Result As float))  
          From tests                            --Note: The Consumed_Tons variable contains tons with both 'Consumed' and 'Received' statuses.  
          Where ((Var_Id = @Good_Tons_Var_Id Or Var_Id = @Consumed_Tons_Var_Id Or Var_Id = @Shipped_Tons_Var_Id) AND   
  Result_On > @Product_Start_Time AND   
  Result_On <= @Product_End_Time AND   
  Result Is Not Null AND   
  cast(Result As float) > 0.000)  
  
          If @Count > 0  
               Select @Good_Tons_Sum  = isnull(@Good_Tons_Sum, 0) + isnull(@Total, 0),  
   @Good_Roll_Count= isnull(@Good_Roll_Count, 0) + @Count  
  
          /* Reject Rolls */  
          Select @Count  = count(Event_Id)  
          From Events  
          Where PU_Id = @Rolls_PU_Id And TimeStamp > @Product_Start_Time And TimeStamp <= @Product_End_Time And Event_Status = @Reject_Status_Id  
  
          Select @Total = sum(cast(Result As float))  
          From tests   
          Where Var_Id = @Reject_Tons_Var_Id and Result_On > @Product_Start_Time And Result_On <= @Product_End_Time And Result Is Not Null And cast(Result As float) > 0.0  
  
          If @Count > 0  
               Select  @Reject_Tons_Sum  = isnull(@Reject_Tons_Sum, 0) + isnull(@Total, 0),  
        @Reject_Roll_Count = isnull(@Reject_Roll_Count, 0) + @Count  
  
          /* Hold Rolls */  
          Select @Count  = count(Event_Id)  
          From Events  
          Where PU_Id = @Rolls_PU_Id And TimeStamp > @Product_Start_Time And TimeStamp <= @Product_End_Time And Event_Status = @Hold_Status_Id  
  
          Select @Total = sum(cast(Result As float))  
          From tests   
          Where Var_Id = @Hold_Tons_Var_Id and Result_On > @Product_Start_Time And Result_On <= @Product_End_Time And Result Is Not Null And cast(Result As float) > 0.0  
  
          If @Count > 0  
               Select @Hold_Tons_Sum  = isnull(@Hold_Tons_Sum, 0) + isnull(@Total, 0),  
        @Hold_Roll_Count = isnull(@Hold_Roll_Count, 0) + @Count  
  
          /* Fire Rolls */  
          Select @Count  = count(Event_Id)  
          From Events  
          Where PU_Id = @Rolls_PU_Id And TimeStamp > @Product_Start_Time And TimeStamp <= @Product_End_Time And Event_Status = @Fire_Status_Id  
  
          Select @Total = sum(cast(Result As float))  
          From tests   
          Where Var_Id = @Fire_Tons_Var_Id and Result_On > @Product_Start_Time And Result_On <= @Product_End_Time And Result Is Not Null And cast(Result As float) > 0.0  
  
          If @Count > 0  
               Select  @Fire_Tons_Sum  = isnull(@Fire_Tons_Sum, 0) + isnull(@Total, 0),  
        @Fire_Roll_Count = isnull(@Fire_Roll_Count, 0) + @Count  
  
          /* Slab Weight */  
          Select @Total = sum(cast(Result As float)) / 1000,  
      @Count = count(Result)  
          From tests   
          Where Var_Id = @Slab_Var_Id and Result_On > @Product_Start_Time And Result_On <= @Product_End_Time And Result Is Not Null And cast(Result As float) > 0.0  
  
          If @Count > 0  
               Select  @Slab_Sum   = isnull(@Slab_Sum, 0) + @Total  
  
          /* Teardown Weight */  
          Select @Total = sum(cast(Result As float)),  
      @Count = count(Result)  
          From tests   
          Where Var_Id = @Teardown_Var_Id and Result_On > @Product_Start_Time And Result_On <= @Product_End_Time And Result Is Not Null And cast(Result As float) > 0.0  
  
          If @Count > 0  
               Select @Teardown_Sum  = isnull(@Teardown_Sum, 0) + @Total  
  
          /* Repulper Tons */  
          Select @Total = sum(cast(Result As float)),  
      @Count = count(Result)  
          From tests   
          Where Var_Id = @Repulper_Tons_Var_Id and Result_On > @Product_Start_Time And Result_On <= @Product_End_Time And Result Is Not Null  
  
          If @Count > 0  
               Select @Repulper_Tons_Sum  = isnull(@Repulper_Tons_Sum, 0) + @Total  
  
          /* TAY */  
          -- Can optionally replace with Proficy Turnover Weight and add Repulper tons to it.  
          Select @Total = sum(cast(Result As float)),  
      @Count = count(Result)  
          From tests   
          Where Var_Id = @TAY_Var_Id and Result_On > @Product_Start_Time And Result_On <= @Product_End_Time And Result Is Not Null  
  
          If @Count > 0  
               Select @TAY_Sum   = isnull(@TAY_Sum, 0) + @Total  
  
          /* RA */  
          -- Can optionally replace with Proficy Turnover Weight and add Repulper tons to it.  
          Select @Total = sum(cast(Result As float)),  
  @Count = count(Result)  
          From tests   
          Where Var_Id = @RA_Var_Id and Result_On > @Product_Start_Time And Result_On <= @Product_End_Time And Result Is Not Null  
  
          If @Count > 0  
               Select @RA_Sum   = isnull(@RA_Sum, 0) + @Total  
  
  
   /************************************************************************************************  
          *                                         Sheetbreak Time/Count                                                 *  
          ************************************************************************************************/  
          -- Reinitialize  
          Select  @Total  = 0.0  
          Select @Total = convert(float, Sum(Datediff(s,  Case   
       When Start_Time < @Product_Start_Time Then @Product_Start_Time  
              Else Start_Time   
       End,  
           Case   
       When End_Time > @Product_End_Time Or End_Time Is Null Then @Product_End_Time  
        Else End_Time   
       End)))/60  
          From Timed_Event_Details  
          Where PU_Id = @Sheetbreak_PU_Id And (TEStatus_Id <> @Sheetbreak_Invalid_Status_Id Or TEStatus_Id Is Null) And  
                      Start_Time < @Product_End_Time And (End_Time > @Product_Start_Time Or End_Time Is Null)  
  
          Select @Sheetbreak_Time = isnull(@Sheetbreak_Time, 0) + isnull(@Total, 0.0)  
  
          Select @Count = 0  
  
          Select @Count  = floor(sum(cast(Result As Float)))  
          From tests   
          Where Var_Id = @Sheetbreak_Count_Var_Id and Result_On > @Product_Start_Time And Result_On <= @Product_End_Time And Result Is Not Null  
  
          Select @Sheetbreak_Count = isnull(@Sheetbreak_Count, 0) + isnull(@Count, 0)  
  
          /************************************************************************************************  
          *                                         Downtime                                                                      *  
          ************************************************************************************************/  
          Select TOP 1 @Line_Status_Id = Line_Status_Id  
          From Local_PG_Line_Status  
          Where Unit_Id = @Production_PU_Id And Start_DateTime <= @Product_Start_Time  
          Order By Start_DateTime Desc  
  
          Declare Line_Status Cursor For  
          Select Start_DateTime, Line_Status_Id  
          From Local_PG_Line_Status  
          Where Unit_Id = @Production_PU_Id And Start_DateTime > @Product_Start_Time And Start_DateTime < @Product_End_Time  
          Order By Start_DateTime Asc  
          For Read Only  
          Open Line_Status  
  
          Select  @Line_Status_Fetch = 0,  
           @Range_Start_Time  = @Product_Start_Time  
  
          While @Line_Status_Fetch = 0  
                Begin  
                Fetch Next From Line_Status Into @LS_Start_Time, @Next_Line_Status_Id  
                Select @Line_Status_Fetch = @@FETCH_STATUS  
                If @Line_Status_Fetch = 0  
                     Select @Range_End_Time  = @LS_Start_Time  
                Else  
                     Select @Range_End_Time = @Product_End_Time  
  
               Select  @Total  = 0.0  
               Select @Total = convert(float, Sum(Datediff(s,  Case   
       When Start_Time < @Range_Start_Time Then @Range_Start_Time  
              Else Start_Time   
       End,  
           Case   
       When End_Time > @Range_End_Time Or End_Time Is Null Then @Range_End_Time  
        Else End_Time   
       End)))/3600  
               From Timed_Event_Details  
               Where PU_Id = @Downtime_PU_Id And (TEStatus_Id <> @Downtime_Invalid_Status_Id Or TEStatus_Id Is Null) And  
                           Start_Time < @Range_End_Time And (End_Time > @Range_Start_Time Or End_Time Is Null)  
  
                If @Line_Status_Id = @GE_Run_Id Or @Line_Status_Id = @GE_Non_Run_Id  
                     Select   @GE_Downtime = isnull(@GE_Downtime, 0) + isnull(@Total, 0.0),  
              @GE_Uptime = isnull(@GE_Uptime, 0) + convert(float, datediff(s, @Range_Start_Time, @Range_End_Time))/3600-isnull(@Total, 0.0)  
                Else   
                     Select   @GI_Downtime = isnull(@GI_Downtime, 0) + isnull(@Total, 0.0),  
              @GI_Uptime = isnull(@GI_Uptime, 0) + convert(float, datediff(s, @Range_Start_Time, @Range_End_Time))/3600-isnull(@Total, 0.0)  
  
                Select @Range_Start_Time = @Range_End_Time  
  Select @Line_Status_Id = @Next_Line_Status_Id  
                End  
  
          Close Line_Status  
          Deallocate Line_Status  
  
          Select @Count = 0  
  
          Select @Count  = floor(sum(cast(Result As Float)))  
          From tests   
          Where Var_Id = @Downtime_Count_Var_Id and Result_On > @Product_Start_Time And Result_On <= @Product_End_Time And Result Is Not Null  
  
          Select @Downtime_Count = isnull(@Downtime_Count, 0) + isnull(@Count, 0)  
  
          /************************************************************************************************  
          *                                        Forming Wire Life                                                           *  
          ************************************************************************************************/  
          -- Reinitialize  
          Select  @Total = 0.00  
          Select @Total = convert(float, Sum(Datediff(s,  Case   
       When Start_Time < @Product_Start_Time Then @Product_Start_Time  
              Else Start_Time   
       End,  
           Case   
       When End_Time > @Product_End_Time Or End_Time Is Null Then @Product_End_Time  
        Else End_Time   
       End)))/3600  
          From Timed_Event_Details  
          Where PU_Id = @Forming_Wire_PU_Id And  
                      Start_Time < @Product_End_Time And (End_Time > @Product_Start_Time Or End_Time Is Null)  
  
          Select @Forming_Wire_Life = isnull(@Forming_Wire_Life, 0) + (@Product_Time/60 - isnull(@Total, 0.0))  
          Select @Backing_Wire_Life = @Forming_Wire_Life  
  
          /************************************************************************************************  
          *                                           Belt Life                                           *  
          ************************************************************************************************/  
          -- Reinitialize  
          Select  @Total = 0.0  
          Select @Total = convert(float, Sum(Datediff(s,  Case   
       When Start_Time < @Product_Start_Time Then @Product_Start_Time  
              Else Start_Time   
       End,  
           Case   
       When End_Time > @Product_End_Time Or End_Time Is Null Then @Product_End_Time  
        Else End_Time   
       End)))/3600  
          From Timed_Event_Details  
          Where PU_Id = @Belt_PU_Id And  
                      Start_Time < @Product_End_Time And (End_Time > @Product_Start_Time Or End_Time Is Null)  
  
  
          Select @Belt_Life = isnull(@Belt_Life, 0) + (@Product_Time/60 - isnull(@Total, 0.0))  
  
          /************************************************************************************************  
          *                                           Blades                                              *  
          ************************************************************************************************/  
          /* Get Blades */  
          Select @Cleaning_Blades = IsNull(@Cleaning_Blades, 0) + count(Event_Id)  
          From Events  
          Where PU_Id = @Cleaning_Blade_PU_Id  and TimeStamp >= @Product_Start_Time And TimeStamp < @Product_End_Time  
  
          Select @Creping_Blades = IsNull(@Creping_Blades, 0) + count(Event_Id)  
          From Events  
          Where PU_Id = @Creping_Blade_PU_Id  and TimeStamp >= @Product_Start_Time And TimeStamp < @Product_End_Time  
  
          /************************************************************************************************  
          *                                           Materials                                           *  
          ************************************************************************************************/  
          If @3rd_Furnish_Var_Id Is Not Null  
               Select @3rd_Furnish_Sum = IsNull(@3rd_Furnish_Sum, 0) + IsNull(Sum(cast(Result As float)), 0) From tests Where Result_On > @Product_Start_Time And Result_On <= @Product_End_Time And Var_Id = @3rd_Furnish_Var_Id  
          If @CTMP_Var_Id Is Not Null  
               Select @CTMP_Sum = IsNull(@CTMP_Sum, 0) + IsNull(Sum(cast(Result As float)), 0) From tests Where Result_On > @Product_Start_Time And Result_On <= @Product_End_Time And Var_Id = @CTMP_Var_Id  
          If @Fiber_1_Var_Id Is Not Null  
               Select @Fiber_1_Sum = IsNull(@Fiber_1_Sum, 0) + IsNull(Sum(cast(Result As float)), 0) From tests Where Result_On > @Product_Start_Time And Result_On <= @Product_End_Time And Var_Id = @Fiber_1_Var_Id  
          If @Fiber_2_Var_Id Is Not Null  
               Select @Fiber_2_Sum = IsNull(@Fiber_2_Sum, 0) + IsNull(Sum(cast(Result As float)), 0) From tests Where Result_On > @Product_Start_Time And Result_On <= @Product_End_Time And Var_Id = @Fiber_2_Var_Id  
          If @Long_Fiber_Var_Id Is Not Null  
               Select @Long_Fiber_Sum = IsNull(@Long_Fiber_Sum, 0) + IsNull(Sum(cast(Result As float)), 0) From tests Where Result_On > @Product_Start_Time And Result_On <= @Product_End_Time And Var_Id = @Long_Fiber_Var_Id  
          If @Short_Fiber_Var_Id Is Not Null  
               Select @Short_Fiber_Sum = IsNull(@Short_Fiber_Sum, 0) + IsNull(Sum(cast(Result As float)), 0) From tests Where Result_On > @Product_Start_Time And Result_On <= @Product_End_Time And Var_Id = @Short_Fiber_Var_Id  
  
          If @Absorb_Aid_Towel_Var_Id Is Not Null  
               Select @Absorb_Aid_Towel_Sum = IsNull(@Absorb_Aid_Towel_Sum, 0) + IsNull(Sum(cast(Result As float)), 0) From tests Where Result_On > @Product_Start_Time And Result_On <= @Product_End_Time And Var_Id = @Absorb_Aid_Towel_Var_Id  
          If @Aloe_E_Additive_Var_Id Is Not Null  
               Select @Aloe_E_Additive_Sum = IsNull(@Aloe_E_Additive_Sum, 0) + IsNull(Sum(cast(Result As float)), 0) From tests Where Result_On > @Product_Start_Time And Result_On <= @Product_End_Time And Var_Id = @Aloe_E_Additive_Var_Id  
          If @Biocide_Var_Id Is Not Null  
               Select @Biocide_Sum = IsNull(@Biocide_Sum, 0) + IsNull(Sum(cast(Result As float)), 0) From tests Where Result_On > @Product_Start_Time And Result_On <= @Product_End_Time And Var_Id = @Biocide_Var_Id  
          If @Cat_Promoter_Var_Id Is Not Null  
               Select @Cat_Promoter_Sum = IsNull(@Cat_Promoter_Sum, 0) + IsNull(Sum(cast(Result As float)), 0) From tests Where Result_On > @Product_Start_Time And Result_On <= @Product_End_Time And Var_Id = @Cat_Promoter_Var_Id  
          If @Chem_1_Var_Id Is Not Null  
               Select @Chem_1_Sum = IsNull(@Chem_1_Sum, 0) + IsNull(Sum(cast(Result As float)), 0) From tests Where Result_On > @Product_Start_Time And Result_On <= @Product_End_Time And Var_Id = @Chem_1_Var_Id  
          If @Chem_2_Var_Id Is Not Null  
               Select @Chem_2_Sum = IsNull(@Chem_2_Sum, 0) + IsNull(Sum(cast(Result As float)), 0) From tests Where Result_On > @Product_Start_Time And Result_On <= @Product_End_Time And Var_Id = @Chem_2_Var_Id  
          If @Chlorine_Control_Var_Id Is Not Null  
               Select @Chlorine_Control_Sum = IsNull(@Chlorine_Control_Sum, 0) + IsNull(Sum(cast(Result As float)), 0) From tests Where Result_On > @Product_Start_Time And Result_On <= @Product_End_Time And Var_Id = @Chlorine_Control_Var_Id  
          If @Defoamer_Var_Id Is Not Null  
               Select @Defoamer_Sum = IsNull(@Defoamer_Sum, 0) + IsNull(Sum(cast(Result As float)), 0) From tests Where Result_On > @Product_Start_Time And Result_On <= @Product_End_Time And Var_Id = @Defoamer_Var_Id  
          If @Dry_Strength_Facial_Var_Id Is Not Null  
               Select @Dry_Strength_Facial_Sum = IsNull(@Dry_Strength_Facial_Sum, 0) + IsNull(Sum(cast(Result As float)), 0) From tests Where Result_On > @Product_Start_Time And Result_On <= @Product_End_Time And Var_Id = @Dry_Strength_Facial_Var_Id  
          If @Dry_Strength_Tissue_Var_Id Is Not Null  
               Select @Dry_Strength_Tissue_Sum = IsNull(@Dry_Strength_Tissue_Sum, 0) + IsNull(Sum(cast(Result As float)), 0) From tests Where Result_On > @Product_Start_Time And Result_On <= @Product_End_Time And Var_Id = @Dry_Strength_Tissue_Var_Id  
          If @Dry_Strength_Towel_Var_Id Is Not Null  
               Select @Dry_Strength_Towel_Sum = IsNull(@Dry_Strength_Towel_Sum, 0) + IsNull(Sum(cast(Result As float)), 0) From tests Where Result_On > @Product_Start_Time And Result_On <= @Product_End_Time And Var_Id = @Dry_Strength_Towel_Var_Id  
          If @Dye_1_Var_Id Is Not Null  
               Select @Dye_1_Sum = IsNull(@Dye_1_Sum, 0) + IsNull(Sum(cast(Result As float)), 0) From tests Where Result_On > @Product_Start_Time And Result_On <= @Product_End_Time And Var_Id = @Dye_1_Var_Id  
          If @Dye_2_Var_Id Is Not Null  
               Select @Dye_2_Sum = IsNull(@Dye_2_Sum, 0) + IsNull(Sum(cast(Result As float)), 0) From tests Where Result_On > @Product_Start_Time And Result_On <= @Product_End_Time And Var_Id = @Dye_2_Var_Id  
          If @Emulsion_1_Var_Id Is Not Null  
               Select @Emulsion_1_Sum = IsNull(@Emulsion_1_Sum, 0) + IsNull(Sum(cast(Result As float)), 0) From tests Where Result_On > @Product_Start_Time And Result_On <= @Product_End_Time And Var_Id = @Emulsion_1_Var_Id  
          If @Emulsion_2_Var_Id Is Not Null  
               Select @Emulsion_2_Sum = IsNull(@Emulsion_2_Sum, 0) + IsNull(Sum(cast(Result As float)), 0) From tests Where Result_On > @Product_Start_Time And Result_On <= @Product_End_Time And Var_Id = @Emulsion_2_Var_Id  
          If @Flocculant_Var_Id Is Not Null  
               Select @Flocculant_Sum = IsNull(@Flocculant_Sum, 0) + IsNull(Sum(cast(Result As float)), 0) From tests Where Result_On > @Product_Start_Time And Result_On <= @Product_End_Time And Var_Id = @Flocculant_Var_Id  
          If @Glue_Adhesive_Var_Id Is Not Null  
               Select @Glue_Adhesive_Sum = IsNull(@Glue_Adhesive_Sum, 0) + IsNull(Sum(cast(Result As float)), 0) From tests Where Result_On > @Product_Start_Time And Result_On <= @Product_End_Time And Var_Id = @Glue_Adhesive_Var_Id  
          If @Glue_Crepe_Aid_Var_Id Is Not Null  
               Select @Glue_Crepe_Aid_Sum = IsNull(@Glue_Crepe_Aid_Sum, 0) + IsNull(Sum(cast(Result As float)), 0) From tests Where Result_On > @Product_Start_Time And Result_On <= @Product_End_Time And Var_Id = @Glue_Crepe_Aid_Var_Id  
          If @Glue_Release_Aid_Var_Id Is Not Null  
               Select @Glue_Release_Aid_Sum = IsNull(@Glue_Release_Aid_Sum, 0) + IsNull(Sum(cast(Result As float)), 0) From tests Where Result_On > @Product_Start_Time And Result_On <= @Product_End_Time And Var_Id = @Glue_Release_Aid_Var_Id  
          If @Glue_Total_Var_Id Is Not Null  
               Select @Glue_Total_Sum = IsNull(@Glue_Total_Sum, 0) + IsNull(Sum(cast(Result As float)), 0) From tests Where Result_On > @Product_Start_Time And Result_On <= @Product_End_Time And Var_Id = @Glue_Total_Var_Id  
          If @Machine_Broke_Var_Id Is Not Null  
               Select @Machine_Broke_Sum = IsNull(@Machine_Broke_Sum, 0) + IsNull(Sum(cast(Result As float)), 0) From tests Where Result_On > @Product_Start_Time And Result_On <= @Product_End_Time And Var_Id = @Machine_Broke_Var_Id  
          If @pH_Control_Tissue_Acid_Var_Id Is Not Null  
               Select @pH_Control_Tissue_Acid_Sum = IsNull(@pH_Control_Tissue_Acid_Sum, 0) + IsNull(Sum(cast(Result As float)), 0) From tests Where Result_On > @Product_Start_Time And Result_On <= @Product_End_Time And Var_Id = @pH_Control_Tissue_Acid_Var_Id  
          If @pH_Control_Towel_Base_Var_Id Is Not Null  
               Select @pH_Control_Towel_Base_Sum = IsNull(@pH_Control_Towel_Base_Sum, 0) + IsNull(Sum(cast(Result As float)), 0) From tests Where Result_On > @Product_Start_Time And Result_On <= @Product_End_Time And Var_Id = @pH_Control_Towel_Base_Var_Id
  
          If @Product_Broke_Var_Id Is Not Null  
               Select @Product_Broke_Sum = IsNull(@Product_Broke_Sum, 0) + IsNull(Sum(cast(Result As float)), 0) From tests Where Result_On > @Product_Start_Time And Result_On <= @Product_End_Time And Var_Id = @Product_Broke_Var_Id  
          If @Single_Glue_Var_Id Is Not Null  
               Select @Single_Glue_Sum = IsNull(@Single_Glue_Sum, 0) + IsNull(Sum(cast(Result As float)), 0) From tests Where Result_On > @Product_Start_Time And Result_On <= @Product_End_Time And Var_Id = @Single_Glue_Var_Id  
          If @Softener_Facial_Var_Id Is Not Null  
               Select @Softener_Facial_Sum = IsNull(@Softener_Facial_Sum, 0) + IsNull(Sum(cast(Result As float)), 0) From tests Where Result_On > @Product_Start_Time And Result_On <= @Product_End_Time And Var_Id = @Softener_Facial_Var_Id  
          If @Softener_Tissue_Var_Id Is Not Null  
               Select @Softener_Tissue_Sum = IsNull(@Softener_Tissue_Sum, 0) + IsNull(Sum(cast(Result As float)), 0) From tests Where Result_On > @Product_Start_Time And Result_On <= @Product_End_Time And Var_Id = @Softener_Tissue_Var_Id  
          If @Softener_Towel_Var_Id Is Not Null  
               Select @Softener_Towel_Sum = IsNull(@Softener_Towel_Sum, 0) + IsNull(Sum(cast(Result As float)), 0) From tests Where Result_On > @Product_Start_Time And Result_On <= @Product_End_Time And Var_Id = @Softener_Towel_Var_Id  
          If @Wet_Strength_Facial_Var_Id Is Not Null  
               Select @Wet_Strength_Facial_Sum = IsNull(@Wet_Strength_Facial_Sum, 0) + IsNull(Sum(cast(Result As float)), 0) From tests Where Result_On > @Product_Start_Time And Result_On <= @Product_End_Time And Var_Id = @Wet_Strength_Facial_Var_Id  
          If @Wet_Strength_Tissue_Var_Id Is Not Null  
               Select @Wet_Strength_Tissue_Sum = IsNull(@Wet_Strength_Tissue_Sum, 0) + IsNull(Sum(cast(Result As float)), 0) From tests Where Result_On > @Product_Start_Time And Result_On <= @Product_End_Time And Var_Id = @Wet_Strength_Tissue_Var_Id  
          If @Wet_Strength_Towel_Var_Id Is Not Null  
               Select @Wet_Strength_Towel_Sum = IsNull(@Wet_Strength_Towel_Sum, 0) + IsNull(Sum(cast(Result As float)), 0) From tests Where Result_On > @Product_Start_Time And Result_On <= @Product_End_Time And Var_Id = @Wet_Strength_Towel_Var_Id  
  
          If @Air_Var_Id Is Not Null  
               Select @Air_Sum = IsNull(@Air_Sum, 0) + IsNull(Sum(cast(Result As float)), 0) From tests Where Result_On > @Product_Start_Time And Result_On <= @Product_End_Time And Var_Id = @Air_Var_Id  
          If @Electric_Var_Id Is Not Null  
               Select @Electric_Sum = IsNull(@Electric_Sum, 0) + IsNull(Sum(cast(Result As float)), 0) From tests Where Result_On > @Product_Start_Time And Result_On <= @Product_End_Time And Var_Id = @Electric_Var_Id  
          If @Gas_Var_Id Is Not Null  
               Select @Gas_Sum = IsNull(@Gas_Sum, 0) + IsNull(Sum(cast(Result As float)), 0) From tests Where Result_On > @Product_Start_Time And Result_On <= @Product_End_Time And Var_Id = @Gas_Var_Id  
          If @Steam_Var_Id Is Not Null  
               Select @Steam_Sum = IsNull(@Steam_Sum, 0) + IsNull(Sum(cast(Result As float)), 0) From tests Where Result_On > @Product_Start_Time And Result_On <= @Product_End_Time And Var_Id = @Steam_Var_Id  
          If @Water_Var_Id Is Not Null  
               Select @Water_Sum = IsNull(@Water_Sum, 0) + IsNull(Sum(cast(Result As float)), 0) From tests Where Result_On > @Product_Start_Time And Result_On <= @Product_End_Time And Var_Id = @Water_Var_Id  
          /************************************************************************************************  
          *                                            Speeds                                             *  
          ************************************************************************************************/  
          If @Yankee_Speed_Var_Id Is Not Null  
               Begin  
               Select @Total = Sum(cast(Result As float)),  
                          @Count = count(Result)  
               From tests  
               Where Var_Id = @Yankee_Speed_Var_Id And Result_On >= @Product_Start_Time And Result_On < @Product_End_Time And Result Is Not Null And cast(Result As float) > 0.0  
               If @Count > 0  
                    Select @Yankee_Speed_Count = IsNull(@Yankee_Speed_Count, 0) + @Count,  
                               @Yankee_Speed_Sum = IsNull(@Yankee_Speed_Sum, 0) + @Total  
               End  
  
          If @Reel_Speed_Var_Id Is Not Null  
               Begin  
               Select @Total = Sum(cast(Result As float)),  
                          @Count = count(Result)  
               From tests  
               Where Var_Id = @Reel_Speed_Var_Id And Result_On >= @Product_Start_Time And Result_On < @Product_End_Time And Result Is Not Null And cast(Result As float) > 0.0  
               If @Count > 0  
                    Select @Reel_Speed_Count = IsNull(@Reel_Speed_Count, 0) + @Count,  
                               @Reel_Speed_Sum = IsNull(@Reel_Speed_Sum, 0) + @Total  
               End  
  
          /************************************************************************************************           *                                     Get Quality Data                                          *  
          ************************************************************************************************/  
          If @Basis_Weight_Manual_Var_Id Is Not Null  
               Begin  
               Select @Total = Sum(cast(Result As float)),  
                         @Count = count(Result)  
               From tests  
               Where Var_Id = @Basis_Weight_Manual_Var_Id And Result_On >= @Product_Start_Time And Result_On < @Product_End_Time And Result Is Not Null And cast(Result As float) > 0.0  
               If @Count > 0  
                    Select @Basis_Weight_Manual_Count = IsNull(@Basis_Weight_Manual_Count, 0) + @Count,  
                             @Basis_Weight_Manual_Sum = IsNull(@Basis_Weight_Manual_Sum, 0) + @Total  
               End  
  
          If @Caliper_Average_Roll_A_Var_Id Is Not Null  
               Begin  
               Select @Total = Sum(cast(Result As float)),  
                         @Count = count(Result)  
               From tests  
               Where Var_Id = @Caliper_Average_Roll_A_Var_Id And Result_On >= @Product_Start_Time And Result_On < @Product_End_Time And Result Is Not Null And cast(Result As float) > 0.0  
               If @Count > 0  
                    Select @Caliper_Average_Roll_A_Count = IsNull(@Caliper_Average_Roll_A_Count, 0) + @Count,  
                             @Caliper_Average_Roll_A_Sum = IsNull(@Caliper_Average_Roll_A_Sum, 0) + @Total  
               End  
  
          If @Caliper_Average_Roll_B_Var_Id Is Not Null  
               Begin  
               Select @Total = Sum(cast(Result As float)),  
                         @Count = count(Result)  
               From tests  
               Where Var_Id = @Caliper_Average_Roll_B_Var_Id And Result_On >= @Product_Start_Time And Result_On < @Product_End_Time And Result Is Not Null And cast(Result As float) > 0.0  
               If @Count > 0  
                    Select @Caliper_Average_Roll_B_Count = IsNull(@Caliper_Average_Roll_B_Count, 0) + @Count,  
                             @Caliper_Average_Roll_B_Sum = IsNull(@Caliper_Average_Roll_B_Sum, 0) + @Total  
               End  
  
          If @Caliper_Range_Roll_A_Var_Id Is Not Null  
               Begin  
               Select @Total = Sum(cast(Result As float)),  
                         @Count = count(Result)  
               From tests  
               Where Var_Id = @Caliper_Range_Roll_A_Var_Id And Result_On >= @Product_Start_Time And Result_On < @Product_End_Time And Result Is Not Null And cast(Result As float) > 0.0  
               If @Count > 0  
                    Select @Caliper_Range_Roll_A_Count = IsNull(@Caliper_Range_Roll_A_Count, 0) + @Count,  
                             @Caliper_Range_Roll_A_Sum = IsNull(@Caliper_Range_Roll_A_Sum, 0) + @Total  
               End  
  
          If @Caliper_Range_Roll_B_Var_Id Is Not Null  
               Begin  
               Select @Total = Sum(cast(Result As float)),  
                         @Count = count(Result)  
               From tests  
               Where Var_Id = @Caliper_Range_Roll_B_Var_Id And Result_On >= @Product_Start_Time And Result_On < @Product_End_Time And Result Is Not Null And cast(Result As float) > 0.0  
               If @Count > 0  
                    Select @Caliper_Range_Roll_B_Count = IsNull(@Caliper_Range_Roll_B_Count, 0) + @Count,  
                             @Caliper_Range_Roll_B_Sum = IsNull(@Caliper_Range_Roll_B_Sum, 0) + @Total  
               End  
  
          If @Color_A_Value_Var_Id Is Not Null  
               Begin  
               Select @Total = Sum(cast(Result As float)),  
                         @Count = count(Result)  
               From tests  
               Where Var_Id = @Color_A_Value_Var_Id And Result_On >= @Product_Start_Time And Result_On < @Product_End_Time And Result Is Not Null And cast(Result As float) > 0.0  
               If @Count > 0  
                    Select @Color_A_Value_Count = IsNull(@Color_A_Value_Count, 0) + @Count,  
                             @Color_A_Value_Sum = IsNull(@Color_A_Value_Sum, 0) + @Total  
               End  
  
          If @Color_B_Value_Var_Id Is Not Null  
               Begin  
               Select @Total = Sum(cast(Result As float)),  
                         @Count = count(Result)  
               From tests  
               Where Var_Id = @Color_B_Value_Var_Id And Result_On >= @Product_Start_Time And Result_On < @Product_End_Time And Result Is Not Null And cast(Result As float) > 0.0  
               If @Count > 0  
                    Select @Color_B_Value_Count = IsNull(@Color_B_Value_Count, 0) + @Count,  
                             @Color_B_Value_Sum = IsNull(@Color_B_Value_Sum, 0) + @Total  
               End  
  
          If @Color_L_Value_Var_Id Is Not Null  
               Begin  
               Select @Total = Sum(cast(Result As float)),  
                         @Count = count(Result)  
               From tests  
               Where Var_Id = @Color_L_Value_Var_Id And Result_On >= @Product_Start_Time And Result_On < @Product_End_Time And Result Is Not Null And cast(Result As float) > 0.0  
               If @Count > 0  
                    Select @Color_L_Value_Count = IsNull(@Color_L_Value_Count, 0) + @Count,  
                             @Color_L_Value_Sum = IsNull(@Color_L_Value_Sum, 0) + @Total  
               End  
  
          If @Holes_Large_Measurement_Var_Id Is Not Null  
               Begin  
               Select @Total = Sum(cast(Result As float)),  
                         @Count = count(Result)  
               From tests  
               Where Var_Id = @Holes_Large_Measurement_Var_Id And Result_On >= @Product_Start_Time And Result_On < @Product_End_Time And Result Is Not Null And cast(Result As float) > 0.0  
               If @Count > 0  
                    Select @Holes_Large_Measurement_Count = IsNull(@Holes_Large_Measurement_Count, 0) + @Count,  
                             @Holes_Large_Measurement_Sum = IsNull(@Holes_Large_Measurement_Sum, 0) + @Total  
               End  
  
          If @Holes_Small_Count_Var_Id Is Not Null  
               Begin  
               Select @Total = Sum(cast(Result As float)),  
                         @Count = count(Result)  
               From tests  
               Where Var_Id = @Holes_Small_Count_Var_Id And Result_On >= @Product_Start_Time And Result_On < @Product_End_Time And Result Is Not Null And cast(Result As float) > 0.0  
               If @Count > 0  
                    Select @Holes_Small_Count_Count = IsNull(@Holes_Small_Count_Count, 0) + @Count,  
                             @Holes_Small_Count_Sum = IsNull(@Holes_Small_Count_Sum, 0) + @Total  
               End  
  
          If @Sink_Average_Var_Id Is Not Null  
               Begin  
               Select @Total = Sum(cast(Result As float)),  
                         @Count = count(Result)  
               From tests  
               Where Var_Id = @Sink_Average_Var_Id And Result_On >= @Product_Start_Time And Result_On < @Product_End_Time And Result Is Not Null And cast(Result As float) > 0.0  
               If @Count > 0  
                    Select @Sink_Average_Count = IsNull(@Sink_Average_Count, 0) + @Count,  
                             @Sink_Average_Sum = IsNull(@Sink_Average_Sum, 0) + @Total  
               End  
  
          If @Soft_Tissue_DS_SD_AVG_Var_Id Is Not Null  
               Begin  
               Select @Total = Sum(cast(Result As float)),  
                         @Count = count(Result)  
               From tests  
               Where Var_Id = @Soft_Tissue_DS_SD_AVG_Var_Id And Result_On >= @Product_Start_Time And Result_On < @Product_End_Time And Result Is Not Null And cast(Result As float) > 0.0  
               If @Count > 0  
                    Select @Soft_Tissue_DS_SD_AVG_Count = IsNull(@Soft_Tissue_DS_SD_AVG_Count, 0) + @Count,  
                             @Soft_Tissue_DS_SD_AVG_Sum = IsNull(@Soft_Tissue_DS_SD_AVG_Sum, 0) + @Total  
               End  
  
          If @Soft_Tissue_DS_WR_AVG_Var_Id Is Not Null  
               Begin  
               Select @Total = Sum(cast(Result As float)),  
                         @Count = count(Result)  
               From tests  
               Where Var_Id = @Soft_Tissue_DS_WR_AVG_Var_Id And Result_On >= @Product_Start_Time And Result_On < @Product_End_Time And Result Is Not Null And cast(Result As float) > 0.0  
               If @Count > 0  
                    Select @Soft_Tissue_DS_WR_AVG_Count = IsNull(@Soft_Tissue_DS_WR_AVG_Count, 0) + @Count,  
                             @Soft_Tissue_DS_WR_AVG_Sum = IsNull(@Soft_Tissue_DS_WR_AVG_Sum, 0) + @Total  
               End  
  
          If @Soft_Tissue_TS_SD_AVG_Var_Id Is Not Null  
               Begin  
               Select @Total = Sum(cast(Result As float)),  
                         @Count = count(Result)  
               From tests  
               Where Var_Id = @Soft_Tissue_TS_SD_AVG_Var_Id And Result_On >= @Product_Start_Time And Result_On < @Product_End_Time And Result Is Not Null And cast(Result As float) > 0.0  
               If @Count > 0  
                    Select @Soft_Tissue_TS_SD_AVG_Count = IsNull(@Soft_Tissue_TS_SD_AVG_Count, 0) + @Count,  
                             @Soft_Tissue_TS_SD_AVG_Sum = IsNull(@Soft_Tissue_TS_SD_AVG_Sum, 0) + @Total  
               End  
  
          If @Soft_Tissue_TS_WR_AVG_Var_Id Is Not Null  
               Begin  
               Select @Total = Sum(cast(Result As float)),  
                         @Count = count(Result)  
               From tests  
               Where Var_Id = @Soft_Tissue_TS_WR_AVG_Var_Id And Result_On >= @Product_Start_Time And Result_On < @Product_End_Time And Result Is Not Null And cast(Result As float) > 0.0  
               If @Count > 0  
                    Select @Soft_Tissue_TS_WR_AVG_Count = IsNull(@Soft_Tissue_TS_WR_AVG_Count, 0) + @Count,  
                             @Soft_Tissue_TS_WR_AVG_Sum = IsNull(@Soft_Tissue_TS_WR_AVG_Sum, 0) + @Total  
               End  
  
          If @Specks_Gross_Count_Var_Id Is Not Null  
               Begin  
               Select @Total = Sum(cast(Result As float)),  
                         @Count = count(Result)  
               From tests  
               Where Var_Id = @Specks_Gross_Count_Var_Id And Result_On >= @Product_Start_Time And Result_On < @Product_End_Time And Result Is Not Null And cast(Result As float) > 0.0  
               If @Count > 0  
                    Select @Specks_Gross_Count_Count = IsNull(@Specks_Gross_Count_Count, 0) + @Count,  
                             @Specks_Gross_Count_Sum = IsNull(@Specks_Gross_Count_Sum, 0) + @Total  
               End  
  
          If @Specks_Large_Count_Var_Id Is Not Null  
               Begin  
               Select @Total = Sum(cast(Result As float)),  
                         @Count = count(Result)  
               From tests  
               Where Var_Id = @Specks_Large_Count_Var_Id And Result_On >= @Product_Start_Time And Result_On < @Product_End_Time And Result Is Not Null And cast(Result As float) > 0.0  
               If @Count > 0  
                    Select @Specks_Large_Count_Count = IsNull(@Specks_Large_Count_Count, 0) + @Count,  
                             @Specks_Large_Count_Sum = IsNull(@Specks_Large_Count_Sum, 0) + @Total  
               End  
  
          If @Specks_Red_Count_Var_Id Is Not Null  
               Begin  
               Select @Total = Sum(cast(Result As float)),  
                         @Count = count(Result)  
               From tests  
  
               Where Var_Id = @Specks_Red_Count_Var_Id And Result_On >= @Product_Start_Time And Result_On < @Product_End_Time And Result Is Not Null And cast(Result As float) > 0.0  
               If @Count > 0  
                    Select @Specks_Red_Count_Count = IsNull(@Specks_Red_Count_Count, 0) + @Count,  
                             @Specks_Red_Count_Sum = IsNull(@Specks_Red_Count_Sum, 0) + @Total  
               End  
  
          If @Specks_Small_Count_Var_Id Is Not Null  
               Begin                Select @Total = Sum(cast(Result As float)),  
                         @Count = count(Result)  
               From tests  
               Where Var_Id = @Specks_Small_Count_Var_Id And Result_On >= @Product_Start_Time And Result_On < @Product_End_Time And Result Is Not Null And cast(Result As float) > 0.0  
               If @Count > 0  
                    Select @Specks_Small_Count_Count = IsNull(@Specks_Small_Count_Count, 0) + @Count,  
                             @Specks_Small_Count_Sum = IsNull(@Specks_Small_Count_Sum, 0) + @Total  
               End  
  
          If @Specks_Tiny_Count_Var_Id Is Not Null  
               Begin  
               Select @Total = Sum(cast(Result As float)),  
                         @Count = count(Result)  
               From tests  
               Where Var_Id = @Specks_Tiny_Count_Var_Id And Result_On >= @Product_Start_Time And Result_On < @Product_End_Time And Result Is Not Null And cast(Result As float) > 0.0  
               If @Count > 0  
                    Select @Specks_Tiny_Count_Count = IsNull(@Specks_Tiny_Count_Count, 0) + @Count,  
                             @Specks_Tiny_Count_Sum = IsNull(@Specks_Tiny_Count_Sum, 0) + @Total  
               End  
  
          If @Stretch_CD_Var_Id Is Not Null  
               Begin  
               Select @Total = Sum(cast(Result As float)),  
                         @Count = count(Result)  
               From tests  
               Where Var_Id = @Stretch_CD_Var_Id And Result_On >= @Product_Start_Time And Result_On < @Product_End_Time And Result Is Not Null And cast(Result As float) > 0.0  
               If @Count > 0  
                    Select @Stretch_CD_Count = IsNull(@Stretch_CD_Count, 0) + @Count,  
                             @Stretch_CD_Sum = IsNull(@Stretch_CD_Sum, 0) + @Total  
               End  
  
          If @Stretch_MD_Var_Id Is Not Null  
               Begin  
               Select @Total = Sum(cast(Result As float)),  
                         @Count = count(Result)  
               From tests  
               Where Var_Id = @Stretch_MD_Var_Id And Result_On >= @Product_Start_Time And Result_On < @Product_End_Time And Result Is Not Null And cast(Result As float) > 0.0  
               If @Count > 0  
                    Select @Stretch_MD_Count = IsNull(@Stretch_MD_Count, 0) + @Count,  
                             @Stretch_MD_Sum = IsNull(@Stretch_MD_Sum, 0) + @Total  
               End  
  
          If @Tensile_CD_Var_Id Is Not Null  
               Begin  
               Select @Total = Sum(cast(Result As float)),  
                         @Count = count(Result)  
               From tests  
               Where Var_Id = @Tensile_CD_Var_Id And Result_On >= @Product_Start_Time And Result_On < @Product_End_Time And Result Is Not Null And cast(Result As float) > 0.0  
               If @Count > 0  
                    Select @Tensile_CD_Count = IsNull(@Tensile_CD_Count, 0) + @Count,  
                             @Tensile_CD_Sum = IsNull(@Tensile_CD_Sum, 0) + @Total  
               End  
  
          If @Tensile_MD_Var_Id Is Not Null  
               Begin  
               Select @Total = Sum(cast(Result As float)),  
                         @Count = count(Result)  
               From tests  
               Where Var_Id = @Tensile_MD_Var_Id And Result_On >= @Product_Start_Time And Result_On < @Product_End_Time And Result Is Not Null And cast(Result As float) > 0.0  
               If @Count > 0  
                    Select @Tensile_MD_Count = IsNull(@Tensile_MD_Count, 0) + @Count,  
                             @Tensile_MD_Sum = IsNull(@Tensile_MD_Sum, 0) + @Total  
               End  
  
          If @Tensile_Modulus_CD_Var_Id Is Not Null  
               Begin  
               Select @Total = Sum(cast(Result As float)),  
                         @Count = count(Result)  
               From tests  
               Where Var_Id = @Tensile_Modulus_CD_Var_Id And Result_On >= @Product_Start_Time And Result_On < @Product_End_Time And Result Is Not Null And cast(Result As float) > 0.0  
               If @Count > 0  
                    Select @Tensile_Modulus_CD_Count = IsNull(@Tensile_Modulus_CD_Count, 0) + @Count,  
                             @Tensile_Modulus_CD_Sum = IsNull(@Tensile_Modulus_CD_Sum, 0) + @Total  
               End  
  
          If @Tensile_Modulus_GM_Var_Id Is Not Null  
               Begin  
               Select @Total = Sum(cast(Result As float)),  
                         @Count = count(Result)  
               From tests  
               Where Var_Id = @Tensile_Modulus_GM_Var_Id And Result_On >= @Product_Start_Time And Result_On < @Product_End_Time And Result Is Not Null And cast(Result As float) > 0.0  
               If @Count > 0  
                    Select @Tensile_Modulus_GM_Count = IsNull(@Tensile_Modulus_GM_Count, 0) + @Count,  
                             @Tensile_Modulus_GM_Sum = IsNull(@Tensile_Modulus_GM_Sum, 0) + @Total  
               End  
  
          If @Tensile_Modulus_MD_Var_Id Is Not Null  
               Begin  
               Select @Total = Sum(cast(Result As float)),  
                         @Count = count(Result)  
               From tests  
               Where Var_Id = @Tensile_Modulus_MD_Var_Id And Result_On >= @Product_Start_Time And Result_On < @Product_End_Time And Result Is Not Null And cast(Result As float) > 0.0  
               If @Count > 0  
                    Select @Tensile_Modulus_MD_Count = IsNull(@Tensile_Modulus_MD_Count, 0) + @Count,  
                             @Tensile_Modulus_MD_Sum = IsNull(@Tensile_Modulus_MD_Sum, 0) + @Total  
               End  
  
          If @Tensile_Ratio_Var_Id Is Not Null  
               Begin  
               Select @Total = Sum(cast(Result As float)),  
                         @Count = count(Result)  
               From tests  
               Where Var_Id = @Tensile_Ratio_Var_Id And Result_On >= @Product_Start_Time And Result_On < @Product_End_Time And Result Is Not Null And cast(Result As float) > 0.0  
               If @Count > 0  
                    Select @Tensile_Ratio_Count = IsNull(@Tensile_Ratio_Count, 0) + @Count,  
                             @Tensile_Ratio_Sum = IsNull(@Tensile_Ratio_Sum, 0) + @Total  
               End  
  
          If @Tensile_Total_Var_Id Is Not Null  
               Begin  
               Select @Total = Sum(cast(Result As float)),  
                         @Count = count(Result)  
               From tests  
               Where Var_Id = @Tensile_Total_Var_Id And Result_On >= @Product_Start_Time And Result_On < @Product_End_Time And Result Is Not Null And cast(Result As float) > 0.0  
               If @Count > 0  
                    Select @Tensile_Total_Count = IsNull(@Tensile_Total_Count, 0) + @Count,  
                             @Tensile_Total_Sum = IsNull(@Tensile_Total_Sum, 0) + @Total  
               End  
  
          If @Wet_Burst_Average_Var_Id Is Not Null  
         Begin  
               Select @Total = Sum(cast(Result As float)),  
                         @Count = count(Result)  
               From tests  
               Where Var_Id = @Wet_Burst_Average_Var_Id And Result_On >= @Product_Start_Time And Result_On < @Product_End_Time And Result Is Not Null And cast(Result As float) > 0.0  
               If @Count > 0  
                    Select @Wet_Burst_Average_Count = IsNull(@Wet_Burst_Average_Count, 0) + @Count,  
                             @Wet_Burst_Average_Sum = IsNull(@Wet_Burst_Average_Sum, 0) + @Total  
               End  
  
          If @Wet_Dry_Tissue_Ratio_Var_Id Is Not Null  
               Begin  
  
               Select @Total = Sum(cast(Result As float)),  
                         @Count = count(Result)  
               From tests  
               Where Var_Id = @Wet_Dry_Tissue_Ratio_Var_Id And Result_On >= @Product_Start_Time And Result_On < @Product_End_Time And Result Is Not Null And cast(Result As float) > 0.0  
               If @Count > 0  
                    Select @Wet_Dry_Tissue_Ratio_Count = IsNull(@Wet_Dry_Tissue_Ratio_Count, 0) + @Count,  
                             @Wet_Dry_Tissue_Ratio_Sum = IsNull(@Wet_Dry_Tissue_Ratio_Sum, 0) + @Total  
  
               End  
  
          If @Wet_Dry_Towel_Ratio_Var_Id Is Not Null  
               Begin  
               Select @Total = Sum(cast(Result As float)),  
                         @Count = count(Result)  
               From tests  
               Where Var_Id = @Wet_Dry_Towel_Ratio_Var_Id And Result_On >= @Product_Start_Time And Result_On < @Product_End_Time And Result Is Not Null And cast(Result As float) > 0.0  
               If @Count > 0  
                    Select @Wet_Dry_Towel_Ratio_Count = IsNull(@Wet_Dry_Towel_Ratio_Count, 0) + @Count,  
                             @Wet_Dry_Towel_Ratio_Sum = IsNull(@Wet_Dry_Towel_Ratio_Sum, 0) + @Total  
               End  
  
          If @Wet_Tensile_Average_Var_Id Is Not Null  
               Begin  
               Select @Total = Sum(cast(Result As float)),  
                         @Count = count(Result)  
               From tests  
               Where Var_Id = @Wet_Tensile_Average_Var_Id And Result_On >= @Product_Start_Time And Result_On < @Product_End_Time And Result Is Not Null And cast(Result As float) > 0.0  
               If @Count > 0  
                    Select @Wet_Tensile_Average_Count = IsNull(@Wet_Tensile_Average_Count, 0) + @Count,  
                             @Wet_Tensile_Average_Sum = IsNull(@Wet_Tensile_Average_Sum, 0) + @Total  
               End  
  
          If @Wet_Tensile_CD_Var_Id Is Not Null  
               Begin  
               Select @Total = Sum(cast(Result As float)),  
                         @Count = count(Result)  
               From tests  
               Where Var_Id = @Wet_Tensile_CD_Var_Id And Result_On >= @Product_Start_Time And Result_On < @Product_End_Time And Result Is Not Null And cast(Result As float) > 0.0  
               If @Count > 0  
                    Select @Wet_Tensile_CD_Count = IsNull(@Wet_Tensile_CD_Count, 0) + @Count,  
                             @Wet_Tensile_CD_Sum = IsNull(@Wet_Tensile_CD_Sum, 0) + @Total  
               End  
  
          If @Wet_Tensile_MD_Var_Id Is Not Null  
               Begin  
               Select @Total = Sum(cast(Result As float)),  
                         @Count = count(Result)  
               From tests  
               Where Var_Id = @Wet_Tensile_MD_Var_Id And Result_On >= @Product_Start_Time And Result_On < @Product_End_Time And Result Is Not Null And cast(Result As float) > 0.0  
               If @Count > 0  
                    Select @Wet_Tensile_MD_Count = IsNull(@Wet_Tensile_MD_Count, 0) + @Count,  
                             @Wet_Tensile_MD_Sum = IsNull(@Wet_Tensile_MD_Sum, 0) + @Total  
               End  
  
          If @Wet_Tensile_Ratio_Var_Id Is Not Null  
               Begin  
               Select @Total = Sum(cast(Result As float)),  
                         @Count = count(Result)  
              From tests  
               Where Var_Id = @Wet_Tensile_Ratio_Var_Id And Result_On >= @Product_Start_Time And Result_On < @Product_End_Time And Result Is Not Null And cast(Result As float) > 0.0  
               If @Count > 0  
                    Select @Wet_Tensile_Ratio_Count = IsNull(@Wet_Tensile_Ratio_Count, 0) + @Count,  
                             @Wet_Tensile_Ratio_Sum = IsNull(@Wet_Tensile_Ratio_Sum, 0) + @Total  
               End  
  
          If @Wet_Tensile_Total_Var_Id Is Not Null  
               Begin  
               Select @Total = Sum(cast(Result As float)),  
                         @Count = count(Result)  
               From tests  
               Where Var_Id = @Wet_Tensile_Total_Var_Id And Result_On >= @Product_Start_Time And Result_On < @Product_End_Time And Result Is Not Null And cast(Result As float) > 0.0  
               If @Count > 0  
                    Select @Wet_Tensile_Total_Count = IsNull(@Wet_Tensile_Total_Count, 0) + @Count,  
                             @Wet_Tensile_Total_Sum = IsNull(@Wet_Tensile_Total_Sum, 0) + @Total  
               End  
          /************************************************************************************************  
          *                                     Get Next Record                                           *  
          ************************************************************************************************/  
          Fetch Next From ProductRuns Into @Prod_Id, @Prod_Desc, @Product_Start_Time, @Product_End_Time  
  
          /************************************************************************************************  
          *                                     Return Results                                            *  
          ************************************************************************************************/  
          /* If finished adding up data for a single product or no more products then return data */  
          If @Last_Prod_Id <> @Prod_Id Or @@FETCH_STATUS <> 0  
               Begin  
               Insert Into @Summary_Data (   
      Product,  
      Product_Time,  
      Good_Tons,  
      Reject_Tons,  
      Hold_Tons,  
      Fire_Tons,  
      Slab,  
      Teardown,  
      Repulper_Tons,  
      TAY,  
      RA_Tons,  
      SheetBreak_Time,  
      GI_Downtime,  
      Cleaning_Blades,  
      Creping_Blades,  
      Good_Roll_Count,  
      Reject_Roll_Count,  
      Hold_Roll_Count,  
      Fire_Roll_Count,  
      Sheetbreak_Count,  
      Forming_Wire_Life,  
      Backing_Wire_Life,  
      Belt_Life,  
      Third_Furnish,  
      Absorb_Aid_Towel,  
      Biocide,  
      Cat_Promoter,  
      Chem_1,  
      Chem_2,  
      Chlorine_Control,  
      CTMP,  
      Defoamer,  
      Dry_Strength_Tissue,  
      Dry_Strength_Towel,  
      Dye_1,  
      Dye_2,  
      Emulsion_1,  
      Emulsion_2,  
      Fiber_1,  
      Fiber_2,  
      Flocculant,  
      Glue_Adhesive,  
      Glue_Crepe_Aid,  
      Glue_Release_Aid,  
      Glue_Total,  
      Long_Fiber,  
      Machine_Broke,  
      pH_Control_Tissue_Acid,  
      pH_Control_Towel_Base,  
      Product_Broke,  
      Short_Fiber,  
      Single_Glue,  
      Softener_Tissue,  
      Softener_Towel,  
      Steam,  
      Steam_UOM,  
      Air,  
      Wet_Strength_Tissue,  
      Wet_Strength_Towel,  
      Downtime_Count,  
      GE_Downtime,  
      GI_Uptime,  
      GE_Uptime,  
      Yankee_Speed,  
      Reel_Speed,  
      Electric,  
      Electric_UOM,  
      Gas,  
      Gas_UOM,  
      Water,  
      Water_UOM,  
      Basis_Weight_Manual_Avg,  
      Caliper_Average_Roll_A_Avg,  
      Caliper_Average_Roll_B_Avg ,  
      Caliper_Range_Roll_A_Avg ,  
      Caliper_Range_Roll_B_Avg ,  
      Color_A_Value_Avg,  
      Color_B_Value_Avg,  
      Color_L_Value_Avg,  
      Holes_Large_Measurement_Avg ,  
      Holes_Small_Avg_Avg,  
      Sink_Average_Avg,  
      Soft_Tissue_DS_SD_AVG_Avg ,  
      Soft_Tissue_DS_WR_AVG_Avg ,  
      Soft_Tissue_TS_SD_AVG_Avg ,  
      Soft_Tissue_TS_WR_AVG_Avg ,  
      Specks_Gross_Avg_Avg ,  
      Specks_Large_Avg_Avg ,  
      Specks_Red_Avg_Avg,  
      Specks_Small_Avg_Avg ,  
      Specks_Tiny_Avg_Avg,  
      Stretch_CD_Avg,  
      Stretch_MD_Avg,  
      Tensile_CD_Avg,  
      Tensile_MD_Avg,  
      Tensile_Modulus_CD_Avg ,  
      Tensile_Modulus_GM_Avg ,  
      Tensile_Modulus_MD_Avg ,  
      Tensile_Ratio_Avg,  
      Tensile_Total_Avg,  
      Wet_Burst_Average_Avg ,  
      Wet_Tensile_Average_Avg ,  
      Wet_Tensile_CD_Avg,  
      Wet_Tensile_MD_Avg,  
      Wet_Tensile_Ratio_Avg,  
      Wet_Tensile_Total_Avg,  
      Wet_Dry_Tissue_Ratio_Avg ,  
      Wet_Dry_Towel_Ratio_Avg,  
      Aloe_E_Additive,  
      Softener_Facial,  
      Wet_Strength_Facial,  
      Dry_Strength_Facial)  
  
                Values (     
      @Last_Prod_Desc,  
      @Product_Time,  
      @Good_Tons_Sum,  
      @Reject_Tons_Sum,  
      @Hold_Tons_Sum,  
      @Fire_Tons_Sum,  
      @Slab_Sum,  
      @Teardown_Sum,  
      @Repulper_Tons_Sum,  
      @TAY_Sum / @TNE_Conversion,  
      @RA_Sum / @TNE_Conversion,  
      @Sheetbreak_Time,  
      @GI_Downtime,  
      @Cleaning_Blades,  
      @Creping_Blades,  
      @Good_Roll_Count,  
      @Reject_Roll_Count,  
      @Hold_Roll_Count,  
      @Fire_Roll_Count,  
      @Sheetbreak_Count,  
      @Forming_Wire_Life,  
      @Backing_Wire_Life,  
      @Belt_Life,  
      @3rd_Furnish_Sum / @TNE_Conversion,  
      @Absorb_Aid_Towel_Sum / @KG_Conversion,  
      @Biocide_Sum / @KG_Conversion,  
      @Cat_Promoter_Sum / @KG_Conversion,  
      @Chem_1_Sum / @KG_Conversion,  
      @Chem_2_Sum / @KG_Conversion,  
      @Chlorine_Control_Sum / @KG_Conversion,  
      @CTMP_Sum / @TNE_Conversion,  
      @Defoamer_Sum / @KG_Conversion,  
      @Dry_Strength_Tissue_Sum / @KG_Conversion,  
      @Dry_Strength_Towel_Sum / @KG_Conversion,  
      @Dye_1_Sum / @KG_Conversion,  
      @Dye_2_Sum / @KG_Conversion,  
      @Emulsion_1_Sum / @KG_Conversion,  
      @Emulsion_2_Sum / @KG_Conversion,  
      @Fiber_1_Sum / @TNE_Conversion,  
      @Fiber_2_Sum / @TNE_Conversion,  
      @Flocculant_Sum / @KG_Conversion,  
      @Glue_Adhesive_Sum / @KG_Conversion,  
      @Glue_Crepe_Aid_Sum / @KG_Conversion,  
      @Glue_Release_Aid_Sum / @KG_Conversion,  
      @Glue_Total_Sum / @KG_Conversion,  
      @Long_Fiber_Sum / @TNE_Conversion,  
      @Machine_Broke_Sum / @TNE_Conversion,  
      @pH_Control_Tissue_Acid_Sum / @KG_Conversion,  
      @pH_Control_Towel_Base_Sum / @KG_Conversion,  
      @Product_Broke_Sum / @TNE_Conversion,  
      @Short_Fiber_Sum / @TNE_Conversion,  
      @Single_Glue_Sum / @KG_Conversion,  
      @Softener_Tissue_Sum / @KG_Conversion,  
      @Softener_Towel_Sum / @KG_Conversion,  
      @Steam_Sum,  
      @Steam_UOM,  
      @Air_Sum,  
      @Wet_Strength_Tissue_Sum / @KG_Conversion,  
      @Wet_Strength_Towel_Sum / @KG_Conversion,  
      @Downtime_Count,  
      @GE_Downtime,  
      @GI_Uptime,  
      @GE_Uptime,  
      @Yankee_Speed_Sum / @Yankee_Speed_Count,  
      @Reel_Speed_Sum / @Reel_Speed_Count,  
      @Electric_Sum,  
      @Electric_UOM,  
      @Gas_Sum,  
      @Gas_UOM,  
      @Water_Sum,  
      @Water_UOM,  
      @Basis_Weight_Manual_Sum/@Basis_Weight_Manual_Count,  
      @Caliper_Average_Roll_A_Sum/@Caliper_Average_Roll_A_Count,  
      @Caliper_Average_Roll_B_Sum/@Caliper_Average_Roll_B_Count,  
      @Caliper_Range_Roll_A_Sum/@Caliper_Range_Roll_A_Count,  
      @Caliper_Range_Roll_B_Sum/@Caliper_Range_Roll_B_Count,  
      @Color_A_Value_Sum/@Color_A_Value_Count,  
      @Color_B_Value_Sum/@Color_B_Value_Count,  
      @Color_L_Value_Sum/@Color_L_Value_Count,  
      @Holes_Large_Measurement_Sum/@Holes_Large_Measurement_Count,  
      @Holes_Small_Count_Sum/@Holes_Small_Count_Count,  
      @Sink_Average_Sum/@Sink_Average_Count,  
      @Soft_Tissue_DS_SD_AVG_Sum/@Soft_Tissue_DS_SD_AVG_Count,  
      @Soft_Tissue_DS_WR_AVG_Sum/@Soft_Tissue_DS_WR_AVG_Count,  
      @Soft_Tissue_TS_SD_AVG_Sum/@Soft_Tissue_TS_SD_AVG_Count,  
      @Soft_Tissue_TS_WR_AVG_Sum/@Soft_Tissue_TS_WR_AVG_Count,  
      @Specks_Gross_Count_Sum/@Specks_Gross_Count_Count,  
      @Specks_Large_Count_Sum/@Specks_Large_Count_Count,  
      @Specks_Red_Count_Sum/@Specks_Red_Count_Count,  
      @Specks_Small_Count_Sum/@Specks_Small_Count_Count,  
      @Specks_Tiny_Count_Sum/@Specks_Tiny_Count_Count,  
      @Stretch_CD_Sum/@Stretch_CD_Count,  
      @Stretch_MD_Sum/@Stretch_MD_Count,  
      @Tensile_CD_Sum/@Tensile_CD_Count,  
      @Tensile_MD_Sum/@Tensile_MD_Count,  
      @Tensile_Modulus_CD_Sum/@Tensile_Modulus_CD_Count,  
      @Tensile_Modulus_GM_Sum/@Tensile_Modulus_GM_Count,  
      @Tensile_Modulus_MD_Sum/@Tensile_Modulus_MD_Count,  
      @Tensile_Ratio_Sum/@Tensile_Ratio_Count,  
      @Tensile_Total_Sum/@Tensile_Total_Count,  
      @Wet_Burst_Average_Sum/@Wet_Burst_Average_Count,  
      @Wet_Tensile_Average_Sum/@Wet_Tensile_Average_Count,  
      @Wet_Tensile_CD_Sum/@Wet_Tensile_CD_Count,  
      @Wet_Tensile_MD_Sum/@Wet_Tensile_MD_Count,  
      @Wet_Tensile_Ratio_Sum/@Wet_Tensile_Ratio_Count,  
      @Wet_Tensile_Total_Sum/@Wet_Tensile_Total_Count,  
      @Wet_Dry_Tissue_Ratio_Sum/@Wet_Dry_Tissue_Ratio_Count,  
      @Wet_Dry_Towel_Ratio_Sum/@Wet_Dry_Towel_Ratio_Count,  
      @Aloe_E_Additive_Sum / @KG_Conversion,  
      @Softener_Facial_Sum / @KG_Conversion,  
      @Wet_Strength_Facial_Sum / @KG_Conversion,  
      @Dry_Strength_Facial_Sum / @KG_Conversion)  
  
               If @@FETCH_STATUS = 0  
                    Begin  
                    /* Reinitialize */  
                    Select  @Product_Time    = Null,  
    @Good_Tons_Sum     = Null,  
    @Reject_Tons_Sum    = Null,  
    @Hold_Tons_Sum     = Null,  
    @Fire_Tons_Sum     = Null,  
    @Slab_Sum    = Null,  
    @Teardown_Sum    = Null,  
    @Repulper_Tons_Sum    = Null,  
    @TAY_Sum    = Null,  
    @RA_Sum     = Null,  
    @Sheetbreak_Time   = Null,  
    @Sheetbreak_Count   = Null,  
    @GI_Downtime    = Null,  
    @GI_Uptime    = Null,  
    @GE_Downtime    = Null,  
    @GE_Uptime    = Null,  
    @Downtime_Count    = Null,  
    @Cleaning_Blades   = Null,  
    @Creping_Blades    = Null,  
    @Good_Roll_Count    = Null,  
    @Reject_Roll_Count    = Null,  
    @Hold_Roll_Count   = Null,  
    @Fire_Roll_Count   = Null,  
    @Forming_Wire_Life   = Null,  
    @Backing_Wire_Life   = Null,  
    @Belt_Life    = Null,  
    @Reel_Speed_Count   = Null,  
    @Reel_Speed_Sum    = Null,  
    @Yankee_Speed_Count   = Null,  
    @Yankee_Speed_Sum   = Null,  
    @3rd_Furnish_Sum    = Null,  
    @Absorb_Aid_Towel_Sum    = Null,  
    @Aloe_E_Additive_Sum    = Null,  
    @Biocide_Sum     = Null,  
    @Cat_Promoter_Sum    = Null,  
    @Chem_1_Sum     = Null,  
    @Chem_2_Sum     = Null,  
    @Chlorine_Control_Sum    = Null,  
    @CTMP_Sum     = Null,  
    @Defoamer_Sum     = Null,  
    @Dry_Strength_Facial_Sum  = Null,  
    @Dry_Strength_Tissue_Sum  = Null,  
    @Dry_Strength_Towel_Sum   = Null,  
    @Dye_1_Sum     = Null,  
    @Dye_2_Sum     = Null,  
    @Emulsion_1_Sum    = Null,  
    @Emulsion_2_Sum    = Null,  
    @Fiber_1_Sum     = Null,  
    @Fiber_2_Sum     = Null,  
    @Flocculant_Sum    = Null,  
    @Glue_Adhesive_Sum    = Null,  
    @Glue_Crepe_Aid_Sum    = Null,  
    @Glue_Release_Aid_Sum    = Null,  
    @Glue_Total_Sum    = Null,  
    @Long_Fiber_Sum    = Null,  
    @Machine_Broke_Sum    = Null,  
    @pH_Control_Tissue_Acid_Sum   = Null,  
    @pH_Control_Towel_Base_Sum   = Null,  
    @Product_Broke_Sum    = Null,  
    @Short_Fiber_Sum    = Null,  
    @Single_Glue_Sum    = Null,  
    @Softener_Facial_Sum   = Null,  
    @Softener_Tissue_Sum   = Null,  
    @Softener_Towel_Sum   = Null,  
    @Wet_Strength_Facial_Sum  = Null,  
    @Wet_Strength_Tissue_Sum  = Null,  
    @Wet_Strength_Towel_Sum   = Null,  
    @Air_Sum    = Null,  
    @Electric_Sum    = Null,  
    @Electric_UOM    = Null,  
    @Gas_Sum    = Null,  
    @Gas_UOM    = Null,  
    @Steam_Sum    = Null,  
    @Steam_UOM    = Null,  
    @Water_Sum    = Null,  
    @Water_UOM    = Null,  
    @Basis_Weight_Manual_Sum  = Null,  
    @Caliper_Average_Roll_A_Sum  = Null,  
    @Caliper_Average_Roll_B_Sum  = Null,  
    @Caliper_Range_Roll_A_Sum  = Null,  
    @Caliper_Range_Roll_B_Sum  = Null,  
    @Color_A_Value_Sum   = Null,  
    @Color_B_Value_Sum   = Null,  
    @Color_L_Value_Sum   = Null,  
    @Holes_Large_Measurement_Sum  = Null,  
    @Holes_Small_Count_Sum   = Null,  
    @Sink_Average_Sum   = Null,  
    @Soft_Tissue_DS_SD_AVG_Sum  = Null,  
    @Soft_Tissue_DS_WR_AVG_Sum  = Null,  
    @Soft_Tissue_TS_SD_AVG_Sum  = Null,  
    @Soft_Tissue_TS_WR_AVG_Sum  = Null,  
    @Specks_Gross_Count_Sum   = Null,  
    @Specks_Large_Count_Sum   = Null,  
    @Specks_Red_Count_Sum   = Null,  
    @Specks_Small_Count_Sum   = Null,  
    @Specks_Tiny_Count_Sum   = Null,  
    @Stretch_CD_Sum    = Null,  
    @Stretch_MD_Sum    = Null,  
    @Tensile_CD_Sum    = Null,  
    @Tensile_MD_Sum    = Null,  
    @Tensile_Modulus_CD_Sum   = Null,  
    @Tensile_Modulus_GM_Sum   = Null,  
    @Tensile_Modulus_MD_Sum   = Null,  
    @Tensile_Ratio_Sum   = Null,  
    @Tensile_Total_Sum   = Null,  
    @Wet_Burst_Average_Sum   = Null,  
    @Wet_Tensile_Average_Sum  = Null,  
    @Wet_Tensile_CD_Sum   = Null,  
    @Wet_Tensile_MD_Sum   = Null,  
    @Wet_Tensile_Ratio_Sum   = Null,  
    @Wet_Tensile_Total_Sum   = Null,  
    @Wet_Dry_Tissue_Ratio_Sum  = Null,  
    @Wet_Dry_Towel_Ratio_Sum  = Null,  
    @Basis_Weight_Manual_Count  = Null,  
    @Caliper_Average_Roll_A_Count  = Null,  
    @Caliper_Average_Roll_B_Count  = Null,  
    @Caliper_Range_Roll_A_Count  = Null,  
    @Caliper_Range_Roll_B_Count  = Null,  
    @Color_A_Value_Count   = Null,  
    @Color_B_Value_Count   = Null,  
    @Color_L_Value_Count   = Null,  
    @Holes_Large_Measurement_Count  = Null,  
    @Holes_Small_Count_Count  = Null,  
    @Sink_Average_Count   = Null,  
    @Soft_Tissue_DS_SD_AVG_Count  = Null,  
    @Soft_Tissue_DS_WR_AVG_Count  = Null,  
    @Soft_Tissue_TS_SD_AVG_Count  = Null,  
    @Soft_Tissue_TS_WR_AVG_Count  = Null,  
    @Specks_Gross_Count_Count  = Null,  
    @Specks_Large_Count_Count  = Null,  
    @Specks_Red_Count_Count   = Null,  
    @Specks_Small_Count_Count  = Null,  
    @Specks_Tiny_Count_Count  = Null,  
    @Stretch_CD_Count   = Null,  
    @Stretch_MD_Count   = Null,  
    @Tensile_CD_Count   = Null,  
    @Tensile_MD_Count   = Null,  
    @Tensile_Modulus_CD_Count  = Null,  
    @Tensile_Modulus_GM_Count  = Null,  
    @Tensile_Modulus_MD_Count  = Null,  
    @Tensile_Ratio_Count   = Null,  
    @Tensile_Total_Count   = Null,  
    @Wet_Burst_Average_Count  = Null,  
    @Wet_Tensile_Average_Count  = Null,  
    @Wet_Tensile_CD_Count   = Null,  
    @Wet_Tensile_MD_Count   = Null,  
    @Wet_Tensile_Ratio_Count  = Null,  
    @Wet_Tensile_Total_Count  = Null,  
    @Wet_Dry_Tissue_Ratio_Count  = Null,  
    @Wet_Dry_Towel_Ratio_Count  = Null,  
    @Last_Prod_Id     = @Prod_Id,  
    @Last_Prod_Desc    = @Prod_Desc  
                    End  
               End  
          End  
  
  
Close ProductRuns  
Deallocate ProductRuns  
  
  
-------------------------------------------------------------------------------------  
  
ReturnResultSets:  
  
------------------------------------------------------------------------------------  
  
  
if (select count(*) from @ErrorMessages) > 0   
  
 select * from @ErrorMessages  
  
else  
  
begin  
  
 select * from @ErrorMessages  
  
  
  
----------------------------------------------------------------------  
-- Return Result Set #1  
----------------------------------------------------------------------  
 SELECT   
  sd1.Brand    AS BRAND,  
  Str(sd1.Good_Tons,20,3)   AS GOOD_TNEs,  
  Str(sd1.Reject_Tons,20,3)  AS REJECT_TNEs,  
  Str(sd1.Hold_Tons,20,3)   AS HOLD_TNEs,  
  Str(sd1.Fire_Tons,20,3)   AS FIRE_TNEs,  
  Str(sd1.Slab,20,3)   AS SLAB_TNEs,  
  Str(sd1.Repulper_Tons,20,3)  AS REPULP_TNEs,  
  Str(sd1.Teardown,20,3)   AS TEARDOWN_TNEs,  
  Str(sd1.TAY,20,3)   AS YANKEE_TNEs,  
  Str(sd1.Unexp,20,3)   AS UNEXP_TNEs  
  FROM  
  (  
  SELECT '2'     AS OrderKey,  
   Product     AS  Brand,  
   Coalesce(Sum(Good_Tons),0)   AS   Good_Tons,  
   Coalesce(Sum(Reject_Tons),0)   AS   Reject_Tons,  
   Coalesce(Sum(Hold_Tons),0)   AS  Hold_Tons ,  
   Coalesce(Sum(Fire_Tons),0)   AS  Fire_Tons ,  
   Coalesce(Sum(Slab),0)    AS  Slab ,  
   Coalesce(Sum(Repulper_Tons),0)  AS  Repulper_Tons ,  
   Coalesce(Sum(Teardown),0)   AS  Teardown ,  
   Coalesce(Sum(TAY),0)    AS  TAY,  
   Coalesce(Sum(RA_Tons),0)  As RA_Tons,  
   (Coalesce(Sum(TAY),0)+coalesce(sum(RA_Tons),0))-(Coalesce(Sum(Good_Tons),0)+Coalesce(Sum(Reject_Tons),0)+Coalesce(Sum(Hold_Tons),0)+Coalesce(Sum(Fire_Tons),0)+Coalesce(Sum(Slab),0)+Coalesce(Sum(Repulper_Tons),0)+Coalesce(Sum(Teardown),0)) AS Unexp  
   FROM @Summary_Data  
   GROUP BY Product   
  UNION  
  SELECT '99'              AS  OrderKey,  
   'TOTAL'     AS Brand,  
   Coalesce(Sum(Good_Tons),0)   AS   Good_Tons,  
   Coalesce(Sum(Reject_Tons),0)   AS   Reject_Tons,  
   Coalesce(Sum(Hold_Tons),0)   AS  Hold_Tons ,  
   Coalesce(Sum(Fire_Tons),0)   AS  Fire_Tons ,  
   Coalesce(Sum(Slab),0)    AS  Slab ,  
   Coalesce(Sum(Repulper_Tons),0)  AS  Repulper_Tons ,  
   Coalesce(Sum(Teardown),0)  AS  Teardown ,  
   Coalesce(Sum(TAY),0)    AS  TAY,  
   coalesce(sum(RA_Tons),0)  as RA_Tons,  
   (Coalesce(Sum(TAY),0)+coalesce(sum(RA_Tons),0))-(Coalesce(Sum(Good_Tons),0)+Coalesce(Sum(Reject_Tons),0)+Coalesce(Sum(Hold_Tons),0)+Coalesce(Sum(Fire_Tons),0)+Coalesce(Sum(Slab),0)+Coalesce(Sum(Repulper_Tons),0)+Coalesce(Sum(Teardown),0)) AS Unexp  
   FROM @Summary_Data ) sd1  
  ORDER BY sd1.OrderKey, sd1.Brand  
  
----------------------------------------------------------------------  
-- Return Result Set #2  
----------------------------------------------------------------------  
 SELECT  sd2.Brand AS Brand,  
  NULL  AS Dummy01,  
  NULL  AS Dummy02,  
  Case  
  WHEN  sd2.Good_Tons+sd2.Reject_Tons+sd2.Hold_Tons+sd2.Fire_Tons+sd2.Slab+sd2.Repulper_Tons+sd2.Teardown = 0 THEN NULL  
  WHEN    sd2.Good_Tons+sd2.Reject_Tons+sd2.Hold_Tons+sd2.Fire_Tons+sd2.Slab+sd2.Repulper_Tons+sd2.Teardown > 0 THEN  
        Str((sd2.Good_Tons+sd2.Reject_Tons+sd2.Hold_Tons+sd2.Fire_Tons)/(sd2.Good_Tons+sd2.Reject_Tons+sd2.Hold_Tons+sd2.Fire_Tons+sd2.Slab+sd2.Repulper_Tons+sd2.Teardown)*100,20,2)   
  END AS PMBRPCT,  
  Case  
  WHEN sd2.Good_Tons+sd2.Reject_Tons+sd2.Hold_Tons+sd2.Fire_Tons = 0 THEN NULL  
  WHEN sd2.Good_Tons+sd2.Reject_Tons+sd2.Hold_Tons+sd2.Fire_Tons > 0 THEN  
   Str((1.0-sd2.Reject_Tons/(sd2.Good_Tons+sd2.Reject_Tons+sd2.Hold_Tons+sd2.Fire_Tons))*100,20,2)   
  END AS PMRJPCT,  
  Case  
  WHEN sd2.Product_Time = 0 THEN NULL  
  WHEN sd2.Product_Time > 0 THEN  
   Str((1.0-(sd2.GI_Downtime+sd2.GE_Downtime)/sd2.Product_Time)*100,20,2)   
  END AS PMDTPCT,  
  NULL  AS Dummy06,  
  NULL  AS Dummy07,  
  NULL  AS Dummy08,  
  NULL  AS Dummy09  
  FROM  
  (  
  SELECT '1'     AS OrderKey,  
   Product     AS Brand,  
   Coalesce(Sum(Good_Tons),0)   AS   Good_Tons,  
   Coalesce(Sum(Reject_Tons),0)   AS   Reject_Tons,  
   Coalesce(Sum(Hold_Tons),0)   AS  Hold_Tons,  
   Coalesce(Sum(Fire_Tons),0)   AS  Fire_Tons,  
   Coalesce(Sum(Slab),0)    AS  Slab,  
   Coalesce(Sum(Repulper_Tons),0)  AS  Repulper_Tons,  
   Coalesce(Sum(Teardown),0)  AS  Teardown,  
   Coalesce(Sum(TAY),0)    AS  TAY,  
   coalesce(sum(RA_Tons),0)  as RA_Tons,  
   (Coalesce(Sum(TAY),0)+coalesce(sum(RA_Tons),0))-(Coalesce(Sum(Good_Tons),0)+Coalesce(Sum(Reject_Tons),0)+Coalesce(Sum(Hold_Tons),0)+Coalesce(Sum(Fire_Tons),0)+Coalesce(Sum(Slab),0)+Coalesce(Sum(Repulper_Tons),0)+Coalesce(Sum(Teardown),0)) AS UNEXP,  
   Coalesce(Sum(GI_Uptime),0)   AS  GI_Uptime,  
   Coalesce(Sum(GI_Downtime),0)   AS  GI_Downtime,  
   Coalesce(Sum(GE_Uptime),0)   AS  GE_Uptime,  
   Coalesce(Sum(GE_Downtime),0)   AS  GE_Downtime,  
   Coalesce(Sum(Product_Time),0)/60  AS  Product_Time  
   FROM @Summary_Data  
   GROUP BY Product   
  UNION  
  SELECT '99'     AS OrderKey,  
   'AVERAGE'     AS  Brand,  
   Coalesce(Sum(Good_Tons),0)   AS   Good_Tons,  
   Coalesce(Sum(Reject_Tons),0)   AS   Reject_Tons,  
   Coalesce(Sum(Hold_Tons),0)   AS  Hold_Tons,  
   Coalesce(Sum(Fire_Tons),0)   AS  Fire_Tons,  
   Coalesce(Sum(Slab),0)    AS  Slab,  
   Coalesce(Sum(Repulper_Tons),0)  AS  Repulper_Tons,  
   Coalesce(Sum(Teardown),0)   AS  Teardown,  
   Coalesce(Sum(TAY),0)    AS  TAY,  
   coalesce(sum(RA_Tons),0)  as RA_Tons,  
   (Coalesce(Sum(TAY),0)+coalesce(sum(RA_Tons),0))-(Coalesce(Sum(Good_Tons),0)+Coalesce(Sum(Reject_Tons),0)+Coalesce(Sum(Hold_Tons),0)+Coalesce(Sum(Fire_Tons),0)+Coalesce(Sum(Slab),0)+Coalesce(Sum(Repulper_Tons),0)+Coalesce(Sum(Teardown),0)) AS UNEXP,  
   Coalesce(sum(GI_Uptime),0)   AS  GI_Uptime,  
   Coalesce(Sum(GI_Downtime),0)   AS  GI_Downtime,  
   Coalesce(Sum(GE_Uptime),0)   AS  GE_Uptime,  
   Coalesce(Sum(GE_Downtime),0)   AS  GE_Downtime,  
   Coalesce(Sum(Product_Time),0)/60  AS  Product_Time  
   FROM @Summary_Data  ) sd2  
  ORDER BY sd2.OrderKey, sd2.Brand  
  
----------------------------------------------------------------------  
-- Return Result Set #3  
----------------------------------------------------------------------  
 SELECT  sd3.Brand    AS Brand,  
  Str(sd3.GI_Uptime,20,2)   AS GI_Uptime,    
  Str(sd3.GI_Downtime,20,2)   AS GI_Downtime,   
  Str(sd3.GE_Uptime,20,2)   AS GE_Uptime,  
  Str(sd3.GE_Downtime,20,2)  AS GE_Downtime,  
  Str(sd3.Product_Time,20,2)  AS Product_Time,  
  NULL     AS Dummy6,  
  NULL     AS Dummy7,  
  NULL     AS Dummy8,  
  NULL     AS Dummy9  
  FROM  
  (  
  SELECT '1'              AS  OrderKey,  
   Product     AS Brand,  
   Coalesce(Sum(GI_Uptime),0)   AS  GI_Uptime,  
   Coalesce(Sum(GI_Downtime),0)   AS  GI_Downtime,  
   Coalesce(Sum(GE_Uptime),0)   AS  GE_Uptime,  
   Coalesce(Sum(GE_Downtime),0)   AS  GE_Downtime,  
   Coalesce(Sum(Product_Time),0)/60  AS  Product_Time  
   FROM @Summary_Data  
   GROUP BY Product   
  UNION  
  SELECT '99'     AS OrderKey,  
   'TOTAL'     AS  Brand,  
   Coalesce(sum(GI_Uptime),0)   AS  GI_Uptime,  
   Coalesce(Sum(GI_Downtime),0)   AS  GI_Downtime,  
   Coalesce(Sum(GE_Uptime),0)   AS  GE_Uptime,  
   Coalesce(Sum(GE_Downtime),0)   AS  GE_Downtime,  
   Coalesce(Sum(Product_Time),0)/60  AS  Product_Time  
   FROM @Summary_Data ) sd3  
  ORDER BY sd3.OrderKey, sd3.Brand  
  
----------------------------------------------------------------------  
-- Return Result Set #4  
----------------------------------------------------------------------  
 SELECT  sd4.Brand    AS Brand,  
  Str(sd4.Good_Roll_Count,20,0)  AS Good_Roll_Count,  
  Str(sd4.Reject_Roll_Count,20,0)  AS Reject_Roll_Count,  
  Str(sd4.Hold_Roll_Count,20,0)  AS Hold_Roll_Count,  
  Str(sd4.Fire_Roll_Count,20,0)  AS Fire_Roll_Count,  
  Case  
  WHEN  sd4.Good_Roll_Count+sd4.Reject_Roll_Count+sd4.Hold_Roll_Count+sd4.Fire_Roll_Count = 0 THEN NULL  
  WHEN  sd4.Good_Roll_Count+sd4.Reject_Roll_Count+sd4.Hold_Roll_Count+sd4.Fire_Roll_Count > 0 THEN  
   Str((sd4.Good_Tons+sd4.Reject_Tons+sd4.Hold_Tons+sd4.Fire_Tons)/(sd4.Good_Roll_Count+sd4.Reject_Roll_Count+sd4.Hold_Roll_Count+sd4.Fire_Roll_Count)*1000,20,0)   
  END AS AvgWeightKg,  
  Str(sd4.Cleaning_Blades,20,0)  AS Cleaning_Blades,  
  Str(sd4.Creping_Blades,20,0)  AS Creping_Blades,  
  Str(sd4.Sheetbreak_Count,20,0)  AS Sheetbreak_Count,  
  Str(sd4.Sheetbreak_Time,20,0)  AS Sheetbreak_Time  
  FROM  
  (  
  SELECT '1'     AS OrderKey,  
   Product     AS  Brand,  
   Coalesce(Sum(Good_Tons),0)   AS   Good_Tons,  
   Coalesce(Sum(Reject_Tons),0)   AS   Reject_Tons,  
   Coalesce(Sum(Hold_Tons),0)   AS  Hold_Tons,  
   Coalesce(Sum(Fire_Tons),0)   AS  Fire_Tons,  
   Coalesce(Sum(Good_Roll_Count),0)  AS  Good_Roll_Count,  
   Coalesce(Sum(Reject_Roll_Count),0)  AS  Reject_Roll_Count,  
   Coalesce(Sum(Hold_Roll_Count),0)  AS  Hold_Roll_Count,  
   Coalesce(Sum(Fire_Roll_Count),0)  AS  Fire_Roll_Count,  
   Coalesce(Sum(Cleaning_Blades),0)  AS  Cleaning_Blades,  
   Coalesce(Sum(Creping_Blades),0)  AS  Creping_Blades,  
   Coalesce(Sum(Sheetbreak_Count),0)  AS  Sheetbreak_Count,  
   Coalesce(Sum(SheetBreak_Time),0)  AS  SheetBreak_Time  
   FROM @Summary_Data  
   GROUP BY Product   
  UNION  
  SELECT '99'     AS  OrderKey,  
   'TOTAL'     AS Brand,  
   Coalesce(Sum(Good_Tons),0)   AS   Good_Tons,  
   Coalesce(Sum(Reject_Tons),0)   AS   Reject_Tons,  
   Coalesce(Sum(Hold_Tons),0)   AS  Hold_Tons,  
   Coalesce(Sum(Fire_Tons),0)   AS  Fire_Tons,  
   Coalesce(Sum(Good_Roll_Count),0)  AS  Good_Roll_Count,  
   Coalesce(Sum(Reject_Roll_Count),0)  AS  Reject_Roll_Count,  
   Coalesce(Sum(Hold_Roll_Count),0)  AS  Hold_Roll_Count,  
   Coalesce(Sum(Fire_Roll_Count),0)  AS  Fire_Roll_Count,  
   Coalesce(Sum(Cleaning_Blades),0)  AS  Cleaning_Blades,  
   Coalesce(Sum(Creping_Blades),0)  AS  Creping_Blades,  
   Coalesce(Sum(Sheetbreak_Count),0)  AS  Sheetbreak_Count,  
   Coalesce(Sum(SheetBreak_Time),0)  AS  SheetBreak_Time  
   FROM @Summary_Data ) sd4  
  ORDER BY sd4.OrderKey, sd4.Brand  
  
----------------------------------------------------------------------  
-- Return Result Set #5  
----------------------------------------------------------------------  
 SELECT  sd5.Brand     AS Brand,  
  Case   
   WHEN  sd5.GI_Uptime = 0 THEN NULL  
   WHEN sd5.GI_Uptime > 0 THEN  
    Str(sd5.Good_Roll_Count/sd5.GI_Uptime*24,20,2)  
   END AS  Good_Roll_Per_Day,  
  Case   
   WHEN  sd5.GI_Uptime = 0 THEN NULL  
   WHEN sd5.GI_Uptime > 0 THEN  
    Str(sd5.Reject_Roll_Count/sd5.GI_Uptime*24,20,2)  
   END AS  Reject_Roll_Per_Day,  
  Case   
   WHEN  sd5.GI_Uptime = 0 THEN NULL  
   WHEN sd5.GI_Uptime > 0 THEN  
    Str(sd5.Hold_Roll_Count/sd5.GI_Uptime*24,20,2)  
   END AS  Hold_Roll_Per_Day,  
  Case   
   WHEN  sd5.GI_Uptime = 0 THEN NULL  
   WHEN sd5.GI_Uptime > 0 THEN  
    Str(sd5.Fire_Roll_Count/sd5.GI_Uptime*24,20,2)  
   END AS  Fire_Roll_Per_Day,  
  NULL AS  Dummy5,  
  Case   
   WHEN  sd5.GI_Uptime = 0 THEN NULL  
   WHEN sd5.GI_Uptime > 0 THEN  
    Str(sd5.Cleaning_Blades/sd5.GI_Uptime*24,20,2)  
   END AS  Cleaning_Blades_Per_Day,  
  Case   
   WHEN  sd5.GI_Uptime = 0 THEN NULL  
   WHEN sd5.GI_Uptime > 0 THEN  
    Str(sd5.Creping_Blades/sd5.GI_Uptime*24,20,2)  
   END AS  Creping_Blades_Per_Day,  
  Case   
   WHEN  sd5.GI_Uptime = 0 THEN NULL  
   WHEN sd5.GI_Uptime > 0 THEN  
    Str(sd5.Sheetbreak_Count/sd5.GI_Uptime*24,20,2)  
   END AS  Sheetbreak_Count_Per_Day,  
  Case   
   WHEN  sd5.GI_Uptime = 0 THEN NULL  
   WHEN sd5.GI_Uptime > 0 THEN  
    Str(sd5.SheetBreak_Time/sd5.GI_Uptime*24,20,2)  
   END AS  SheetBreak_Time_Per_Day  
  FROM  
  (  
  SELECT '1'      AS OrderKey,  
   Product      AS  Brand,  
   Coalesce(Sum(GI_Uptime),0)    AS  GI_Uptime,  
   Coalesce(Sum(Good_Roll_Count),0)   AS  Good_Roll_Count,  
   Coalesce(Sum(Reject_Roll_Count),0)   AS  Reject_Roll_Count,  
   Coalesce(Sum(Hold_Roll_Count),0)   AS  Hold_Roll_Count,  
   Coalesce(Sum(Fire_Roll_Count),0)   AS  Fire_Roll_Count,  
   Coalesce(Sum(Cleaning_Blades),0)   AS  Cleaning_Blades,  
   Coalesce(Sum(Creping_Blades),0)   AS  Creping_Blades,  
   Coalesce(Sum(Sheetbreak_Count),0)   AS  Sheetbreak_Count,  
   Coalesce(Sum(SheetBreak_Time),0)   AS  SheetBreak_Time  
   FROM @Summary_Data  
   GROUP BY Product   
  UNION  
  SELECT '99'      AS  OrderKey,  
   'AVERAGE'     AS Brand,  
   Coalesce(Sum(GI_Uptime),0)    AS  GI_Uptime,  
   Coalesce(Sum(Good_Roll_Count),0)   AS  Good_Roll_Count,  
   Coalesce(Sum(Reject_Roll_Count),0)   AS  Reject_Roll_Count,  
   Coalesce(Sum(Hold_Roll_Count),0)   AS  Hold_Roll_Count,  
   Coalesce(Sum(Fire_Roll_Count),0)   AS  Fire_Roll_Count,  
   Coalesce(Sum(Cleaning_Blades),0)   AS  Cleaning_Blades,  
   Coalesce(Sum(Creping_Blades),0)   AS  Creping_Blades,  
   Coalesce(Sum(Sheetbreak_Count),0)   AS  Sheetbreak_Count,  
   Coalesce(Sum(SheetBreak_Time),0)   AS  SheetBreak_Time  
   FROM @Summary_Data ) sd5  
  ORDER BY sd5.OrderKey, sd5.Brand  
  
----------------------------------------------------------------------  
-- Return Result Set #6  
----------------------------------------------------------------------  
 SELECT  sd6.Brand     AS Brand,  
  Str(sd6.Long_Fiber,20,3)   AS Long_Fiber,  
  Str(sd6.short_Fiber,20,3)   AS Short_Fiber,  
  Str(sd6.Third_Furnish,20,3)   AS Third_Furnish,  
  Str(sd6.Machine_Broke,20,3)   AS Machine_Broke,  
  Str(sd6.Product_Broke,20,3)   AS Product_Broke,  
  Str(sd6.CTMP,20,3)    AS CTMP,  
  Str(sd6.Fiber_1,20,3)    AS Fiber_1,  
  Str(sd6.Fiber_2,20,3)    AS Fiber_2,  
  Case  
   WHEN sd6.TAY = 0 THEN NULL  
   WHEN sd6.TAY > 0 THEN   
    Str((sd6.Long_Fiber+sd6.short_Fiber+sd6.Third_Furnish+sd6.Machine_Broke+sd6.Product_Broke+sd6.CTMP+sd6.Fiber_1+sd6.Fiber_2)/sd6.TAY,20,3)  
  END  AS Fiber  
  FROM  
  (  
  SELECT '1'              AS  OrderKey,  
   Product      AS  Brand,  
   Coalesce(sum(Long_Fiber),0)     AS  Long_Fiber ,  
   Coalesce(sum(Short_Fiber),0)    AS  Short_Fiber ,  
    Coalesce(sum(Third_Furnish),0)    AS  Third_Furnish ,  
   Coalesce(sum(Machine_Broke),0)    AS  Machine_Broke ,  
   Coalesce(sum(Product_Broke),0)    AS  Product_Broke ,  
   Coalesce(sum(CTMP),0)      AS  CTMP ,  
   Coalesce(sum(Fiber_1),0)     AS  Fiber_1 ,  
   Coalesce(sum(Fiber_2),0)     AS  Fiber_2 ,  
   Coalesce(Sum(TAY),0)     AS  TAY,  
   coalesce(sum(RA_Tons),0)   as RA_Tons  
   FROM @Summary_Data  
   GROUP BY Product   
  UNION  
  SELECT '99'      AS  OrderKey,  
   'TOTAL'      AS Brand,  
   Coalesce(sum(Long_Fiber),0)     AS  Long_Fiber ,  
   Coalesce(sum(Short_Fiber),0)     AS  Short_Fiber ,  
    Coalesce(sum(Third_Furnish),0)    AS  Third_Furnish ,  
   Coalesce(sum(Machine_Broke),0)    AS  Machine_Broke ,  
   Coalesce(sum(Product_Broke),0)    AS  Product_Broke ,  
   Coalesce(sum(CTMP),0)      AS  CTMP ,  
   Coalesce(sum(Fiber_1),0)     AS  Fiber_1 ,  
   Coalesce(sum(Fiber_2),0)     AS  Fiber_2 ,  
   Coalesce(Sum(TAY),0)     AS  TAY,  
   coalesce(sum(RA_Tons),0)   as RA_Tons  
   FROM @Summary_Data ) sd6  
  ORDER BY sd6.OrderKey, sd6.Brand  
----------------------------------------------------------------------  
-- Return Result Set #7  
----------------------------------------------------------------------  
 SELECT  sd7.Brand     AS Brand,  
  Case  
   WHEN sd7.Long_Fiber+sd7.Short_Fiber+sd7.Third_Furnish+sd7.Product_Broke+sd7.CTMP = 0 THEN NULL  
   WHEN sd7.Long_Fiber+sd7.Short_Fiber+sd7.Third_Furnish+sd7.Product_Broke+sd7.CTMP > 0 THEN  
   str(sd7.Long_Fiber/(sd7.Long_Fiber+sd7.Short_Fiber+sd7.Third_Furnish+sd7.Product_Broke+sd7.CTMP)*100,20,2)   
   END AS Long_Fiber_Pct,  
  Case   
   WHEN sd7.Long_Fiber+sd7.Short_Fiber+sd7.Third_Furnish+sd7.Product_Broke+sd7.CTMP = 0 THEN NULL  
   WHEN sd7.Long_Fiber+sd7.Short_Fiber+sd7.Third_Furnish+sd7.Product_Broke+sd7.CTMP > 0 THEN  
   str(sd7.Short_Fiber/(sd7.Long_Fiber+sd7.Short_Fiber+sd7.Third_Furnish+sd7.Product_Broke+sd7.CTMP)*100,20,2)   
   END AS Short_Fiber_Pct,  
  Case  
   WHEN sd7.Long_Fiber+sd7.Short_Fiber+sd7.Third_Furnish+sd7.Product_Broke+sd7.CTMP = 0 THEN NULL  
   WHEN sd7.Long_Fiber+sd7.Short_Fiber+sd7.Third_Furnish+sd7.Product_Broke+sd7.CTMP > 0 THEN  
   str(sd7.Third_Furnish/(sd7.Long_Fiber+sd7.Short_Fiber+sd7.Third_Furnish+sd7.Product_Broke+sd7.CTMP)*100,20,2)   
   END AS Third_Furnish_Pct,  
  NULL AS Machine_Brk_Pct,  
  Case  
   WHEN sd7.Long_Fiber+sd7.Short_Fiber+sd7.Third_Furnish+sd7.Product_Broke+sd7.CTMP = 0 THEN NULL  
   WHEN sd7.Long_Fiber+sd7.Short_Fiber+sd7.Third_Furnish+sd7.Product_Broke+sd7.CTMP > 0 THEN  
   str(sd7.Product_Broke/(sd7.Long_Fiber+sd7.Short_Fiber+sd7.Third_Furnish+sd7.Product_Broke+sd7.CTMP)*100,20,2)   
   END AS Product_Brk_Pct,  
  Case  
   WHEN sd7.Long_Fiber+sd7.Short_Fiber+sd7.Third_Furnish+sd7.Product_Broke+sd7.CTMP = 0 THEN NULL  
   WHEN sd7.Long_Fiber+sd7.Short_Fiber+sd7.Third_Furnish+sd7.Product_Broke+sd7.CTMP > 0 THEN  
   str(sd7.CTMP/(sd7.Long_Fiber+sd7.Short_Fiber+sd7.Third_Furnish+sd7.Product_Broke+sd7.CTMP)*100,20,2)    
   END AS CTMP_Pct,  
  Case  
   WHEN sd7.Long_Fiber+sd7.Short_Fiber+sd7.Third_Furnish+sd7.Product_Broke+sd7.CTMP = 0 THEN NULL  
   WHEN sd7.Long_Fiber+sd7.Short_Fiber+sd7.Third_Furnish+sd7.Product_Broke+sd7.CTMP > 0 THEN  
   str(sd7.Fiber_1/(sd7.Long_Fiber+sd7.Short_Fiber+sd7.Third_Furnish+sd7.Product_Broke+sd7.CTMP)*100,20,2)  
   END AS Fiber_1_Pct,  
  Case  
   WHEN sd7.Long_Fiber+sd7.Short_Fiber+sd7.Third_Furnish+sd7.Product_Broke+sd7.CTMP = 0 THEN NULL  
   WHEN sd7.Long_Fiber+sd7.Short_Fiber+sd7.Third_Furnish+sd7.Product_Broke+sd7.CTMP > 0 THEN  
   str(sd7.Fiber_2/(sd7.Long_Fiber+sd7.Short_Fiber+sd7.Third_Furnish+sd7.Product_Broke+sd7.CTMP)*100,20,2)   
   END AS Fiber_2_Pct,  
  Case  
   WHEN sd7.Long_Fiber+sd7.Short_Fiber+sd7.Third_Furnish+sd7.Product_Broke+sd7.CTMP = 0 THEN NULL  
   WHEN sd7.Long_Fiber+sd7.Short_Fiber+sd7.Third_Furnish+sd7.Product_Broke+sd7.CTMP > 0 THEN  
   str((sd7.Long_Fiber+sd7.Short_Fiber+sd7.Third_Furnish+sd7.Product_Broke+sd7.CTMP+sd7.Fiber_1+sd7.Fiber_2)/(sd7.Long_Fiber+sd7.Short_Fiber+sd7.Third_Furnish+sd7.Product_Broke+sd7.CTMP)*100,20,2)  
   END  AS Total_Pct  
  FROM  
  (  
  SELECT '1'      AS OrderKey,  
   Product      AS  Brand,  
   Coalesce(sum(Long_Fiber),0)     AS  Long_Fiber ,  
   Coalesce(sum(Short_Fiber),0)    AS  Short_Fiber ,  
    Coalesce(sum(Third_Furnish),0)    AS  Third_Furnish ,  
   Coalesce(sum(Machine_Broke),0)    AS  Machine_Broke ,  
   Coalesce(sum(Product_Broke),0)    AS  Product_Broke ,  
   Coalesce(sum(CTMP),0)      AS  CTMP,  
   Coalesce(sum(Fiber_1),0)     AS  Fiber_1,  
   Coalesce(sum(Fiber_2),0)     AS  Fiber_2  
   FROM @Summary_Data  
   GROUP BY Product   
  UNION  
  SELECT '99'      AS  OrderKey,  
   'AVERAGE'      AS Brand,  
   Coalesce(sum(Long_Fiber),0)     AS  Long_Fiber ,  
   Coalesce(sum(Short_Fiber),0)     AS  Short_Fiber ,  
    Coalesce(sum(Third_Furnish),0)    AS  Third_Furnish ,  
   Coalesce(sum(Machine_Broke),0)    AS  Machine_Broke ,  
   Coalesce(sum(Product_Broke),0)    AS  Product_Broke ,  
   Coalesce(sum(CTMP),0)      AS  CTMP,  
   Coalesce(sum(Fiber_1),0)     AS  Fiber_1,  
   Coalesce(sum(Fiber_2),0)     AS  Fiber_2  
   FROM @Summary_Data ) sd7  
  ORDER BY sd7.OrderKey, sd7.Brand  
  
  
----------------------------------------------------------------------  
-- Return Result Set #8  
----------------------------------------------------------------------  
 SELECT  sd8.Brand     AS Brand,  
  str(sd8.Absorb_Aid_Towel,20,2)    AS  Absorb_Aid_Towel ,  
  str(sd8.Biocide,20,2)     AS  Biocide ,  
  str(sd8.Cat_Promoter,20,2)    AS  Cat_Promoter ,  
  str(sd8.Chem_1,20,2)    AS  Chem_1 ,  
  str(sd8.Chem_2,20,2)     AS  Chem_2 ,  
  str(sd8.Chlorine_Control,20,2)    AS  Chlorine_Control ,  
  str(sd8.Defoamer,20,2)     AS  Defoamer ,  
  str(sd8.Dry_Strength_Tissue,20,2)   AS  Dry_Strength_Tissue ,  
  str(sd8.Dry_Strength_Towel,20,2)   AS  Dry_Strength_Towel  
  FROM  
  (   
  SELECT '1'      AS OrderKey,  
   Product      AS  Brand,  
   Coalesce(sum(Absorb_Aid_Towel),NULL)   AS  Absorb_Aid_Towel ,  
   Coalesce(sum(Biocide),NULL)    AS  Biocide ,  
   Coalesce(sum(Cat_Promoter),NULL)   AS  Cat_Promoter ,  
   Coalesce(sum(Chem_1),NULL)    AS  Chem_1 ,  
   Coalesce(sum(Chem_2),NULL)    AS  Chem_2 ,  
   Coalesce(sum(Chlorine_Control),NULL)   AS  Chlorine_Control ,  
   Coalesce(sum(Defoamer),NULL)    AS  Defoamer ,  
   Coalesce(sum(Dry_Strength_Tissue),NULL)  AS  Dry_Strength_Tissue ,  
   Coalesce(sum(Dry_Strength_Towel),NULL)   AS  Dry_Strength_Towel  
   FROM @Summary_Data  
   GROUP BY Product   
  UNION  
  SELECT '99'      AS  OrderKey,  
   'TOTAL'      AS Brand,  
   Coalesce(sum(Absorb_Aid_Towel),NULL)   AS  Absorb_Aid_Towel ,  
   Coalesce(sum(Biocide),NULL)    AS  Biocide ,  
   Coalesce(sum(Cat_Promoter),NULL)    AS  Cat_Promoter ,  
   Coalesce(sum(Chem_1),NULL)    AS  Chem_1 ,  
   Coalesce(sum(Chem_2),NULL)    AS  Chem_2 ,  
   Coalesce(sum(Chlorine_Control),NULL)   AS  Chlorine_Control ,  
   Coalesce(sum(Defoamer),NULL)    AS  Defoamer ,  
   Coalesce(sum(Dry_Strength_Tissue),NULL)   AS  Dry_Strength_Tissue ,  
   Coalesce(sum(Dry_Strength_Towel),NULL)   AS  Dry_Strength_Towel  
   FROM @Summary_Data ) sd8  
   ORDER BY sd8.OrderKey, sd8.Brand  
  
----------------------------------------------------------------------  
-- Return Result Set #9  
----------------------------------------------------------------------    
SELECT  sd9.Brand     AS Brand,  
  Case  
   WHEN sd9.Tay = 0 THEN NULL  
   WHEN sd9.Tay > 0 THEN  
   str(sd9.Absorb_Aid_Towel/sd9.Tay,20,2)     
   END AS  Absorb_Aid_Towel_Per_YKT,  
  Case  
   WHEN sd9.Tay = 0 THEN NULL  
   WHEN sd9.Tay > 0 THEN  
   str(sd9.Biocide/sd9.Tay,20,2)      
   END  AS  Biocide_Per_YKT,  
  Case  
   WHEN sd9.Tay = 0 THEN NULL  
   WHEN sd9.Tay > 0 THEN  
   str(sd9.Cat_Promoter/sd9.Tay,20,2)     
   END AS  Cat_Promoter_Per_YKT,  
  Case  
   WHEN sd9.Tay = 0 THEN NULL  
   WHEN sd9.Tay > 0 THEN  
   str(sd9.Chem_1/sd9.Tay,20,2)     
   END  AS  Chem_1_Per_YKT,  
  Case  
   WHEN sd9.Tay = 0 THEN NULL  
   WHEN sd9.Tay > 0 THEN  
   str(sd9.Chem_2/sd9.Tay,20,2)      
   END AS  Chem_2_Per_YKT,  
  Case  
   WHEN sd9.Tay = 0 THEN NULL  
   WHEN sd9.Tay > 0 THEN  
   str(sd9.Chlorine_Control/sd9.Tay,20,2)     
   END AS  Chlorine_Control_Per_YKT,  
  Case  
   WHEN sd9.Tay = 0 THEN NULL  
   WHEN sd9.Tay > 0 THEN  
   str(sd9.Defoamer/sd9.Tay,20,2)      
   END AS  Defoamer_Per_YKT,  
  Case  
   WHEN sd9.Tay = 0 THEN NULL  
   WHEN sd9.Tay > 0 THEN  
   str(sd9.Dry_Strength_Tissue/sd9.Tay,20,2)    
   END AS  Dry_Strength_Tissue_Per_YKT,  
  Case  
   WHEN sd9.Tay = 0 THEN NULL  
   WHEN sd9.Tay > 0 THEN  
   str(sd9.Dry_Strength_Towel/sd9.Tay,20,2)    
   END AS  Dry_Strength_Towel_Per_YKT  
  FROM  
  (   
  SELECT '1'      AS OrderKey,  
   Product      AS  Brand,  
   Coalesce(sum(Absorb_Aid_Towel),NULL)   AS  Absorb_Aid_Towel ,  
   Coalesce(sum(Biocide),NULL)    AS  Biocide ,  
   Coalesce(sum(Cat_Promoter),NULL)   AS  Cat_Promoter ,  
   Coalesce(sum(Chem_1),NULL)    AS  Chem_1 ,  
   Coalesce(sum(Chem_2),NULL)    AS  Chem_2 ,  
   Coalesce(sum(Chlorine_Control),NULL)   AS  Chlorine_Control ,  
   Coalesce(sum(Defoamer),NULL)    AS  Defoamer ,  
   Coalesce(sum(Dry_Strength_Tissue),NULL)  AS  Dry_Strength_Tissue ,  
   Coalesce(sum(Dry_Strength_Towel),NULL)   AS  Dry_Strength_Towel,  
   Coalesce(sum(TAY),0)    AS Tay,  
   coalesce(sum(RA_Tons),0)   as RA_Tons  
   FROM @Summary_Data  
   GROUP BY Product   
  UNION  
  SELECT '99'      AS  OrderKey,  
   'AVERAGE'     AS Brand,  
   Coalesce(sum(Absorb_Aid_Towel),NULL)   AS  Absorb_Aid_Towel ,  
   Coalesce(sum(Biocide),NULL)    AS  Biocide ,  
   Coalesce(sum(Cat_Promoter),NULL)   AS  Cat_Promoter ,  
   Coalesce(sum(Chem_1),NULL)    AS  Chem_1 ,  
   Coalesce(sum(Chem_2),NULL)    AS  Chem_2 ,  
   Coalesce(sum(Chlorine_Control),NULL)   AS  Chlorine_Control ,  
   Coalesce(sum(Defoamer),NULL)    AS  Defoamer ,  
   Coalesce(sum(Dry_Strength_Tissue),NULL)  AS  Dry_Strength_Tissue ,  
   Coalesce(sum(Dry_Strength_Towel),NULL)   AS  Dry_Strength_Towel,  
   Coalesce(sum(TAY),0)    AS Tay,  
   Coalesce(Sum(RA_Tons),0)   as RA_Tons  
   FROM @Summary_Data ) sd9  
   ORDER BY sd9.OrderKey, sd9.Brand    
  
----------------------------------------------------------------------  
-- Return Result Set #10  
----------------------------------------------------------------------  
 SELECT  sd10.Brand     AS Brand,  
  str(sd10.Dye_1,20,2)     AS  Dye_1 ,  
  str(sd10.Dye_2,20,2)     AS  Dye_2 ,  
  str(sd10.Emulsion_1,20,2)    AS  Emulsion_1 ,  
  str(sd10.Emulsion_2,20,2)    AS  Emulsion_2 ,  
  str(sd10.Flocculant,20,2)    AS  Flocculant ,  
  str(sd10.Glue_Adhesive,20,2)    AS  Glue_Adhesive ,  
  str(sd10.Glue_Crepe_Aid,20,2)    AS  Glue_Crepe_Aid ,  
  str(sd10.Glue_Release_Aid,20,2)   AS  Glue_Release_Aid ,  
  str(sd10.Glue_Total,20,2)    AS  Glue_Total  
  FROM  
  (   
  SELECT '1'      AS OrderKey,  
   Product      AS  Brand,  
   Coalesce(sum(Dye_1),NULL)    AS  Dye_1 ,  
   Coalesce(sum(Dye_2),NULL)    AS  Dye_2 ,  
   Coalesce(sum(Emulsion_1),NULL)    AS  Emulsion_1 ,    Coalesce(sum(Emulsion_2),NULL)    AS  Emulsion_2 ,  
   Coalesce(sum(Flocculant),NULL)    AS  Flocculant ,  
   Coalesce(sum(Glue_Adhesive),NULL)   AS  Glue_Adhesive ,  
   Coalesce(sum(Glue_Crepe_Aid),NULL)   AS  Glue_Crepe_Aid ,  
   Coalesce(sum(Glue_Release_Aid),NULL)   AS  Glue_Release_Aid ,  
   Coalesce(sum(Glue_Total),NULL)    AS  Glue_Total  
   FROM @Summary_Data  
   GROUP BY Product   
  UNION  
  SELECT '99'      AS  OrderKey,  
   'TOTAL'      AS Brand,  
   Coalesce(sum(Dye_1),NULL)    AS  Dye_1 ,  
   Coalesce(sum(Dye_2) ,NULL)   AS  Dye_2 ,  
   Coalesce(sum(Emulsion_1),NULL)    AS  Emulsion_1 ,  
   Coalesce(sum(Emulsion_2),NULL)    AS  Emulsion_2 ,  
   Coalesce(sum(Flocculant),NULL)    AS  Flocculant ,  
   Coalesce(sum(Glue_Adhesive),NULL)   AS  Glue_Adhesive ,  
   Coalesce(sum(Glue_Crepe_Aid),NULL)   AS  Glue_Crepe_Aid ,  
   Coalesce(sum(Glue_Release_Aid),NULL)   AS  Glue_Release_Aid ,  
   Coalesce(sum(Glue_Total),NULL)    AS  Glue_Total  
   FROM @Summary_Data ) sd10  
   ORDER BY sd10.OrderKey, sd10.Brand   
  
----------------------------------------------------------------------  
-- Return Result Set #11  
----------------------------------------------------------------------  
 SELECT  sd11.Brand  AS Brand,  
  Case  
   WHEN sd11.Tay = 0 THEN NULL  
   WHEN sd11.Tay > 0 THEN  
   str(sd11.Dye_1/sd11.Tay,20,2)     
   END AS  Dye_l_Per_YKT,  
  Case  
   WHEN sd11.Tay = 0 THEN NULL  
   WHEN sd11.Tay > 0 THEN  
   str(sd11.Dye_2/sd11.Tay,20,2)      
   END  AS  Dye_2_Per_YKT,  
  Case  
   WHEN sd11.Tay = 0 THEN NULL  
   WHEN sd11.Tay > 0 THEN  
   str(sd11.Emulsion_1/sd11.Tay,20,2)     
   END AS  Emulsion_1_Per_YKT,  
  Case  
   WHEN sd11.Tay = 0 THEN NULL  
   WHEN sd11.Tay > 0 THEN  
   str(sd11.Emulsion_2/sd11.Tay,20,2)     
   END  AS  Emulsion_2_Per_YKT,  
  Case  
   WHEN sd11.Tay = 0 THEN NULL  
   WHEN sd11.Tay > 0 THEN  
   str(sd11.Flocculant/sd11.Tay,20,2)      
   END AS  Flocculant_Per_YKT,  
  Case  
   WHEN sd11.Tay = 0 THEN NULL  
   WHEN sd11.Tay > 0 THEN  
   str(sd11.Glue_Adhesive/sd11.Tay,20,2)     
   END AS  Glue_Adhesive_Per_YKT,  
  Case  
   WHEN sd11.Tay = 0 THEN NULL  
   WHEN sd11.Tay > 0 THEN  
   str(sd11.Glue_Crepe_Aid/sd11.Tay,20,2)      
   END AS  Glue_Crepe_Aid_Per_YKT,  
  Case  
   WHEN sd11.Tay = 0 THEN NULL  
   WHEN sd11.Tay > 0 THEN  
   str(sd11.Glue_Release_Aid/sd11.Tay,20,2)    
   END AS  Glue_Release_Aid_Per_YKT,  
  Case  
   WHEN sd11.Tay = 0 THEN NULL  
   WHEN sd11.Tay > 0 THEN  
   str(sd11.Glue_Total/sd11.Tay,20,2)    
   END AS  Glue_Total_Per_YKT  
  FROM  
  (   
  SELECT '1'      AS OrderKey,  
   Product      AS  Brand,  
   Coalesce(sum(Dye_1),NULL)    AS  Dye_1 ,  
   Coalesce(sum(Dye_2),NULL)    AS  Dye_2 ,  
   Coalesce(sum(Emulsion_1),NULL)    AS  Emulsion_1 ,  
   Coalesce(sum(Emulsion_2),NULL)    AS  Emulsion_2 ,  
   Coalesce(sum(Flocculant),NULL)    AS  Flocculant ,  
   Coalesce(sum(Glue_Adhesive),NULL)   AS  Glue_Adhesive ,  
   Coalesce(sum(Glue_Crepe_Aid),NULL)   AS  Glue_Crepe_Aid ,  
   Coalesce(sum(Glue_Release_Aid),NULL)   AS  Glue_Release_Aid ,  
   Coalesce(sum(Glue_Total),NULL)    AS  Glue_Total,  
   Coalesce(sum(TAY),0)    AS Tay,  
   coalesce(sum(RA_Tons),0)   as RA_Tons  
   FROM @Summary_Data  
   GROUP BY Product   
  UNION  
  SELECT '99'      AS  OrderKey,  
   'AVERAGE'     AS Brand,  
   Coalesce(sum(Dye_1),NULL)    AS  Dye_1 ,  
   Coalesce(sum(Dye_2) ,NULL)   AS  Dye_2 ,  
   Coalesce(sum(Emulsion_1),NULL)    AS  Emulsion_1 ,  
   Coalesce(sum(Emulsion_2),NULL)    AS  Emulsion_2 ,  
   Coalesce(sum(Flocculant),NULL)    AS  Flocculant ,  
   Coalesce(sum(Glue_Adhesive),NULL)   AS  Glue_Adhesive ,  
   Coalesce(sum(Glue_Crepe_Aid),NULL)   AS  Glue_Crepe_Aid ,  
   Coalesce(sum(Glue_Release_Aid),NULL)   AS  Glue_Release_Aid ,  
   Coalesce(sum(Glue_Total),NULL)    AS  Glue_Total,  
   Coalesce(sum(TAY),0)    AS Tay,  
   Coalesce(sum(RA_Tons),0)   as RA_Tons  
   FROM @Summary_Data ) sd11  
   ORDER BY sd11.OrderKey, sd11.Brand  
  
----------------------------------------------------------------------  
-- Return Result Set #12  
----------------------------------------------------------------------  
 SELECT  sd12.Brand     AS Brand,  
  str(sd12.pH_Control_Tissue_Acid,20,2)   AS  pH_Control_Towel_Acid,  
  str(sd12.pH_Control_Towel_Base,20,2)   AS  pH_Control_Towel_Base,  
  str(sd12.Single_Glue,20,2)    AS  Single_Glue,  
  str(sd12.Softener_Tissue,20,2)    AS  Softener_Tissue,  
  str(sd12.Softener_Towel,20,2)    AS  Softener_Towel,  
  str(sd12.Wet_Strength_Tissue,20,2)   AS  Wet_Strength_Tissue,  
  str(sd12.Wet_Strength_Towel,20,2)   AS  Wet_Strength_Towel,  
  NULL      AS Dummy8,  
  NULL      AS Dummy9  
  FROM  
  (   
  SELECT '1'      AS OrderKey,  
   Product      AS  Brand,  
   Coalesce(sum(pH_Control_Tissue_Acid),NULL)  AS  pH_Control_Tissue_Acid,  
   Coalesce(sum(pH_Control_Towel_Base),NULL)  AS  pH_Control_Towel_Base,  
   Coalesce(sum(Single_Glue),NULL)   AS  Single_Glue,  
   Coalesce(sum(Softener_Tissue),NULL)   AS  Softener_Tissue,  
   Coalesce(sum(Softener_Towel),NULL)   AS  Softener_Towel,  
   Coalesce(sum(Wet_Strength_Tissue),NULL)  AS  Wet_Strength_Tissue,  
   Coalesce(sum(Wet_Strength_Towel),NULL)   AS  Wet_Strength_Towel  
   FROM @Summary_Data  
   GROUP BY Product   
  UNION  
  SELECT '99'      AS  OrderKey,  
   'TOTAL'      AS Brand,  
   Coalesce(sum(pH_Control_Tissue_Acid),NULL)  AS  pH_Control_Tissue_Acid,  
   Coalesce(sum(pH_Control_Towel_Base),NULL)  AS  pH_Control_Towel_Base,  
   Coalesce(sum(Single_Glue),NULL)   AS  Single_Glue,  
   Coalesce(sum(Softener_Tissue),NULL)   AS  Softener_Tissue,  
   Coalesce(sum(Softener_Towel),NULL)   AS  Softener_Towel,  
   Coalesce(sum(Wet_Strength_Tissue),NULL)  AS  Wet_Strength_Tissue,  
   Coalesce(sum(Wet_Strength_Towel),NULL)   AS  Wet_Strength_Towel  
   FROM @Summary_Data ) sd12  
   ORDER BY sd12.OrderKey, sd12.Brand   
  
----------------------------------------------------------------------  
-- Return Result Set #13  
----------------------------------------------------------------------  
 SELECT  sd13.Brand     AS Brand,  
  Case  
   WHEN sd13.Tay = 0 THEN NULL  
   WHEN sd13.Tay > 0 THEN  
   str(sd13.pH_Control_Tissue_Acid/sd13.Tay,20,2)     
   END AS  pH_Control_Tissue_Acid_Per_YKT,  
  Case  
   WHEN sd13.Tay = 0 THEN NULL  
   WHEN sd13.Tay > 0 THEN  
   str(sd13.pH_Control_Towel_Base/sd13.Tay,20,2)      
   END  AS  pH_Control_Towel_Base_Per_YKT,  
  Case  
   WHEN sd13.Tay = 0 THEN NULL  
   WHEN sd13.Tay > 0 THEN  
   str(sd13.Single_Glue/sd13.Tay,20,2)     
   END AS  Single_Glue_Per_YKT,  
  Case  
   WHEN sd13.Tay = 0 THEN NULL  
   WHEN sd13.Tay > 0 THEN  
   str(sd13.Softener_Tissue/sd13.Tay,20,2)     
   END  AS  Softener_Tissue_Per_YKT,  
  Case  
   WHEN sd13.Tay = 0 THEN NULL  
   WHEN sd13.Tay > 0 THEN  
   str(sd13.Softener_Towel/sd13.Tay,20,2)      
   END AS  Softener_Towel_Per_YKT,  
  Case  
   WHEN sd13.Tay = 0 THEN NULL  
   WHEN sd13.Tay > 0 THEN  
   str(sd13.Wet_Strength_Tissue/sd13.Tay,20,2)     
   END AS  Wet_Strength_Tissue_Per_YKT,  
  Case  
   WHEN sd13.Tay = 0 THEN NULL  
   WHEN sd13.Tay > 0 THEN  
   str(sd13.Wet_Strength_Towel/sd13.Tay,20,2)      
   END AS  Wet_Strength_Towel_Per_YKT,  
  NULL AS Dummy8,  
  NULL AS Dummy9  
  FROM  
  (   
  SELECT '1'      AS OrderKey,  
   Product      AS  Brand,  
   Coalesce(sum(pH_Control_Tissue_Acid),NULL)  AS  pH_Control_Tissue_Acid,  
   Coalesce(sum(pH_Control_Towel_Base),NULL)  AS  pH_Control_Towel_Base,  
   Coalesce(sum(Single_Glue),NULL)   AS  Single_Glue,  
   Coalesce(sum(Softener_Tissue),NULL)   AS  Softener_Tissue,  
   Coalesce(sum(Softener_Towel),NULL)   AS  Softener_Towel,  
   Coalesce(sum(Wet_Strength_Tissue),NULL)  AS  Wet_Strength_Tissue,  
   Coalesce(sum(Wet_Strength_Towel),NULL)   AS  Wet_Strength_Towel,  
   Coalesce(sum(TAY),0)    AS Tay,  
   coalesce(sum(RA_Tons),0)   as RA_Tons  
   FROM @Summary_Data  
   GROUP BY Product   
  UNION  
  SELECT '99'      AS  OrderKey,  
   'AVERAGE'     AS Brand,  
   Coalesce(sum(pH_Control_Tissue_Acid),NULL)  AS  pH_Control_Tissue_Acid,  
   Coalesce(sum(pH_Control_Towel_Base),NULL)  AS  pH_Control_Towel_Base,  
   Coalesce(sum(Single_Glue),NULL)   AS  Single_Glue,  
   Coalesce(sum(Softener_Tissue),NULL)   AS  Softener_Tissue,  
   Coalesce(sum(Softener_Towel),NULL)   AS  Softener_Towel,  
   Coalesce(sum(Wet_Strength_Tissue),NULL)  AS  Wet_Strength_Tissue,  
   Coalesce(sum(Wet_Strength_Towel),NULL)   AS  Wet_Strength_Towel,  
   Coalesce(sum(TAY),0)    AS Tay,  
   coalesce(sum(RA_Tons),0)   as RA_Tons  
   FROM @Summary_Data ) sd13  
   ORDER BY sd13.OrderKey, sd13.Brand   
  
----------------------------------------------------------------------  
-- Return Result Set #14  
----------------------------------------------------------------------  
 SELECT  sd14.Brand     AS Brand,  
  str(sd14.Steam,20,2)     AS  Steam,    
  sd14.Steam_UOM     As Steam_UOM,  
  str(sd14.Electric,20,2)    AS  Electric,    
  sd14.Electric_UOM    As Electric_UOM,  
  str(sd14.Air,20,2)     AS  Air,  
  str(sd14.Gas,20,2)     AS  Gas,    
  sd14.Gas_UOM     As Gas_UOM,  
  str(sd14.Water,20,2)     AS  Water,   
  sd14.Water_UOM     As Water_UOM    
  FROM  
  (   
  SELECT '1'      AS OrderKey,  
   Product      AS  Brand,  
   Coalesce(sum(Steam),NULL)    AS  Steam,  
   Max(Steam_UOM)     As Steam_UOM,  
   Coalesce(sum(Electric),NULL)    AS  Electric,  
   Max(Electric_UOM)    As Electric_UOM,  
   Coalesce(sum(Air),NULL)    AS  Air,  
   Coalesce(sum(Gas),NULL)    AS  Gas,  
   Max(Gas_UOM)     As Gas_UOM,  
   Coalesce(sum(Water),NULL)    AS  Water,  
   Max(Water_UOM)     As Water_UOM  
   FROM @Summary_Data  
   GROUP BY Product   
  UNION  
  SELECT '99'      AS  OrderKey,  
   'TOTAL'      AS Brand,  
   Coalesce(sum(Steam),NULL)    AS  Steam,  
   Max(Steam_UOM)     As Steam_UOM,  
   Coalesce(sum(Electric),NULL)    AS  Electric,  
   Max(Electric_UOM)    As Electric_UOM,  
   Coalesce(sum(Air),NULL)    AS  Air,  
   Coalesce(sum(Gas),NULL)    AS  Gas,  
   Max(Gas_UOM)     As Gas_UOM,  
   Coalesce(sum(Water),NULL)    AS  Water,  
   Max(Water_UOM)     As Water_UOM  
   FROM @Summary_Data ) sd14  
   ORDER BY sd14.OrderKey, sd14.Brand   
  
----------------------------------------------------------------------  
-- Return Result Set #15  
----------------------------------------------------------------------  
 SELECT  sd15.Brand AS Brand,  
  Case  
   WHEN sd15.Tay = 0 THEN NULL  
   WHEN sd15.Tay > 0 THEN  
   str(sd15.Steam/sd15.Tay,20,2)      
   END AS  Steam_Per_YKT,  
  Case  
   WHEN sd15.Tay = 0 THEN NULL  
   WHEN sd15.Tay > 0 THEN  
   str(sd15.Electric/sd15.Tay,20,2)     
   END AS  Electric_Per_YKT,  
  Case  
   WHEN sd15.Tay = 0 THEN NULL  
   WHEN sd15.Tay > 0 THEN  
   str(sd15.Air/sd15.Tay,20,2)      
   END  AS  Air_Per_YKT,  
  Case  
   WHEN sd15.Tay = 0 THEN NULL  
   WHEN sd15.Tay > 0 THEN  
   str(sd15.Gas/sd15.Tay,20,2)     
   END AS  Gas_Per_YKT,  
  Case  
   WHEN sd15.Tay = 0 THEN NULL  
   WHEN sd15.Tay > 0 THEN  
   str(sd15.Water/sd15.Tay,20,2)     
   END  AS  Water_Per_YKT,  
  NULL AS Dummy6,  
  NULL AS Dummy7,  
  NULL AS Dummy8,  
  NULL AS Dummy9  
  FROM  
  (   
  SELECT '1'      AS OrderKey,  
   Product      AS  Brand,  
   Coalesce(sum(Steam),NULL)    AS  Steam,  
   Coalesce(sum(Electric),NULL)    AS  Electric,  
   Coalesce(sum(Air),NULL)    AS  Air,  
   Coalesce(sum(Gas),NULL)    AS  Gas,  
   Coalesce(sum(Water),NULL)    AS  Water,  
   Coalesce(sum(TAY),0)    AS Tay,  
   Coalesce(sum(RA_Tons),0)   as RA_Tons  
   FROM @Summary_Data  
   GROUP BY Product   
  UNION  
  SELECT '99'      AS  OrderKey,  
   'AVERAGE'     AS Brand,  
   Coalesce(sum(Steam),NULL)    AS  Steam,  
   Coalesce(sum(Electric),NULL)    AS  Electric,  
   Coalesce(sum(Air),NULL)    AS  Air,  
   Coalesce(sum(Gas),NULL)    AS  Gas,  
   Coalesce(sum(Water),NULL)    AS  Water,  
   Coalesce(sum(TAY),0)    AS Tay,  
   coalesce(sum(RA_Tons),0)   as RA_Tons  
   FROM @Summary_Data ) sd15  
   ORDER BY sd15.OrderKey, sd15.Brand   
  
----------------------------------------------------------------------  
-- Return Result Set #16  
----------------------------------------------------------------------  
 SELECT  sd16.Brand     AS Brand,  
  sd16.Basis_Weight_Manual_Avg   AS Basis_Weight_Manual_Avg,  
  sd16.Caliper_Average_Roll_A_Avg   AS Caliper_Average_Roll_A_Avg,  
  sd16.Caliper_Range_Roll_A_Avg   AS Caliper_Range_Roll_A_Avg,  
  sd16.Caliper_Average_Roll_B_Avg   AS Caliper_Average_Roll_B_Avg,  
  sd16.Caliper_Range_Roll_B_Avg   AS Caliper_Range_Roll_B_Avg,  
  sd16.Tensile_MD_Avg    AS Tensile_MD_Avg,  
  sd16.Tensile_CD_Avg    AS Tensile_CD_Avg,  
  sd16.Tensile_Ratio_Avg    AS Tensile_Ratio_Avg,  
  sd16.Tensile_Total_Avg    AS Tensile_Total_Avg   
  FROM  
  (   
  SELECT '1'        AS OrderKey,  
   Product        AS  Brand,  
   str(Coalesce(sum(Basis_Weight_Manual_Avg),NULL),20,2)   AS  Basis_Weight_Manual_Avg,  
   str(Coalesce(sum(Caliper_Average_Roll_A_Avg),NULL),20,2)  AS  Caliper_Average_Roll_A_Avg,  
   str(Coalesce(sum(Caliper_Range_Roll_A_Avg),NULL),20,2)   AS  Caliper_Range_Roll_A_Avg,  
   str(Coalesce(sum(Caliper_Average_Roll_B_Avg),NULL),20,2) AS  Caliper_Average_Roll_B_Avg,  
   str(Coalesce(sum(Caliper_Range_Roll_B_Avg),NULL),20,2)   AS  Caliper_Range_Roll_B_Avg,  
   str(Coalesce(sum(Tensile_MD_Avg),NULL),20,2)    AS  Tensile_MD_Avg,  
   str(Coalesce(sum(Tensile_CD_Avg),NULL),20,2)    AS  Tensile_CD_Avg,  
   str(Coalesce(sum(Tensile_Ratio_Avg ),NULL),20,2)   AS  Tensile_Ratio_Avg,  
   str(Coalesce(sum(Tensile_Total_Avg ),NULL),20,2)   AS  Tensile_Total_Avg   
   FROM @Summary_Data  
   GROUP BY Product   
  UNION  
  SELECT '99'      AS  OrderKey,  
   'AVERAGE'     AS Brand,  
   'n/a'       AS  Basis_Weight_Manual_Avg,  
   'n/a'       AS  Caliper_Average_Roll_A_Avg,  
   'n/a'       AS  Caliper_Range_Roll_A_Avg,  
   'n/a'       AS  Caliper_Average_Roll_B_Avg,  
   'n/a'       AS  Caliper_Range_Roll_B_Avg,  
   'n/a'       AS  Tensile_MD_Avg,  
   'n/a'       AS  Tensile_CD_Avg,  
   'n/a'       AS  Tensile_Ratio_Avg,  
   'n/a'       AS  Tensile_Total_Avg  
   FROM @Summary_Data  ) sd16  
   ORDER BY sd16.OrderKey, sd16.Brand   
           
----------------------------------------------------------------------  
-- Return Result Set #17  
----------------------------------------------------------------------  
 SELECT  sd17.Brand     AS Brand,  
  sd17.Stretch_MD_Avg    AS Stretch_MD_Avg,  
  sd17.Stretch_CD_Avg    AS Stretch_CD_Avg,  
  sd17.Sink_Average_Avg    AS Sink_Average_Avg,  
  sd17.Color_A_Value_Avg    AS Color_A_Value_Avg,  
  sd17.Color_B_Value_Avg    AS Color_B_Value_Avg,  
  sd17.Color_L_Value_Avg    AS Color_L_Value_Avg,  
  sd17.Specks_Gross_Avg_Avg   AS Specks_Gross_Avg_Avg,  
  sd17.Specks_Large_Avg_Avg   AS Specks_Large_Avg_Avg,  
  sd17.Specks_Small_Avg_Avg   AS Specks_Small_Avg_Avg  
  FROM  
  (   
  SELECT '1'       AS OrderKey,  
   Product       AS  Brand,  
   str(Coalesce(sum(Stretch_MD_Avg),NULL),20,2)   AS  Stretch_MD_Avg,  
   str(Coalesce(sum(Stretch_CD_Avg),NULL),20,2)   AS  Stretch_CD_Avg,  
   str(Coalesce(sum(Sink_Average_Avg),NULL),20,2)   AS  Sink_Average_Avg,  
   str(Coalesce(sum(Color_A_Value_Avg),NULL),20,2)  AS  Color_A_Value_Avg,  
   str(Coalesce(sum(Color_B_Value_Avg),NULL),20,2)  AS  Color_B_Value_Avg,  
   str(Coalesce(sum(Color_L_Value_Avg),NULL),20,2)  AS  Color_L_Value_Avg,  
   str(Coalesce(sum(Specks_Gross_Avg_Avg),NULL),20,2)  AS  Specks_Gross_Avg_Avg,  
   str(Coalesce(sum(Specks_Large_Avg_Avg),NULL),20,2)  AS  Specks_Large_Avg_Avg,  
   str(Coalesce(sum(Specks_Small_Avg_Avg),NULL),20,2)  AS  Specks_Small_Avg_Avg   
   FROM @Summary_Data  
   GROUP BY Product   
  UNION  
  SELECT '99'      AS  OrderKey,  
   'AVERAGE'     AS Brand,  
   'n/a'       AS  Stretch_MD_Avg,  
   'n/a'       AS  Stretch_CD_Avg,  
   'n/a'       AS  Sink_Average_Avg,  
   'n/a'       AS  Color_A_Value_Avg,  
   'n/a'       AS  Color_B_Value_Avg,  
   'n/a'       AS  Color_L_Value_Avg,  
   'n/a'       AS  Specks_Gross_Avg_Avg,  
   'n/a'       AS  Specks_Large_Avg_Avg,  
   'n/a'       AS  Specks_Small_Avg_Avg  
   FROM @Summary_Data  ) sd17  
   ORDER BY sd17.OrderKey, sd17.Brand   
  
----------------------------------------------------------------------  
-- Return Result Set #18  
----------------------------------------------------------------------  
 SELECT  sd18.Brand     AS Brand,  
  sd18.Specks_Red_avg_avg    AS Specks_Red_avg_avg,  
  sd18.Holes_Small_Avg_Avg   AS Holes_Small_Avg_Avg,  
  sd18.Wet_Burst_Average_Avg   AS Wet_Burst_Average_Avg,  
  Case  
   WHEN sd18.Wet_Dry_Tissue_Ratio_Avg IS NOT NULL THEN sd18.Wet_Dry_Tissue_Ratio_Avg   
   WHEN sd18.Wet_Dry_Tissue_Ratio_Avg IS NULL AND sd18.Wet_Dry_Towel_Ratio_Avg  IS NOT NULL THEN sd18.Wet_Dry_Towel_Ratio_Avg  
   ELSE NULL  
  END AS WBur_Avg,  
  sd18.Wet_Tensile_MD_Avg    AS Wet_Tensile_MD_Avg,  
  sd18.Wet_Tensile_CD_Avg    AS Wet_Tensile_CD_Avg,  
  sd18.Wet_Tensile_Total_Avg   AS Wet_Tensile_Total_Avg,  
  sd18.Wet_Tensile_Ratio_Avg   AS Wet_Tensile_Ratio_Avg,  
  NULL      AS Dummy9  
  FROM  
  (   
  SELECT '1'       AS OrderKey,  
   Product       AS  Brand,  
   str(Coalesce(sum(Specks_Red_avg_avg),NULL),20,2)  AS  Specks_Red_avg_avg,  
   str(Coalesce(sum(Holes_Small_Avg_Avg),NULL),20,2)  AS  Holes_Small_Avg_Avg,  
   str(Coalesce(sum(Wet_Burst_Average_Avg),NULL),20,2)  AS  Wet_Burst_Average_Avg,  
   str(Coalesce(sum(Wet_Dry_Tissue_Ratio_Avg),NULL),20,2) AS  Wet_Dry_Tissue_Ratio_Avg,  
   str(Coalesce(sum(Wet_Dry_Towel_Ratio_Avg),NULL),20,2)  AS  Wet_Dry_Towel_Ratio_Avg,  
   str(Coalesce(sum(Wet_Tensile_MD_Avg),NULL),20,2)  AS  Wet_Tensile_MD_Avg,  
   str(Coalesce(sum(Wet_Tensile_CD_Avg),NULL),20,2)  AS  Wet_Tensile_CD_Avg,  
   str(Coalesce(sum(Wet_Tensile_Total_Avg),NULL),20,2)  AS  Wet_Tensile_Total_Avg,  
   str(Coalesce(sum(Wet_Tensile_Ratio_Avg),NULL),20,2)  AS  Wet_Tensile_Ratio_Avg   
   FROM @Summary_Data  
   GROUP BY Product   
  UNION  
  SELECT '99'      AS  OrderKey,  
   'AVERAGE'     AS Brand,  
   'n/a'       AS  Specks_Red_avg_avg,  
   'n/a'       AS  Holes_Small_Avg_Avg,  
   'n/a'       AS  Wet_Burst_Average_Avg,  
   'n/a'       AS  Wet_Dry_Tissue_Ratio_Avg,  
   'n/a'       AS  Wet_Dry_Towel_Ratio_Avg,  
   'n/a'       AS  Wet_Tensile_MD_Avg,  
   'n/a'       AS  Wet_Tensile_CD_Avg,  
   'n/a'       AS  Wet_Tensile_Total_Avg,  
   'n/a'       AS  Wet_Tensile_Ratio_Avg  
   FROM @Summary_Data  ) sd18  
   ORDER BY sd18.OrderKey, sd18.Brand   
  
  
end -- else for ReturnResultsets  
  
  
/************************************************************************************************  
*                                     Cleanup                                                   *  
************************************************************************************************/  
  
/* Testing....  
Select Product, sum(Product_Time) from @Summary_Data  
group by Product  
  
Select @Time5 = getdate()  
Select Datediff(ms, @Time1, @Time5), Datediff(ms, @Time1, @Time2), Datediff(ms, @Time2, @Time3), Datediff(ms, @Time3, @Time4), Datediff(ms, @Time4, @Time5)  
*/  
  
  

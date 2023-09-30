 /*  
Stored Procedure: spLocal_RptPmkgTurnoverQuality  
Author:   M. Wells (MSI)  
Date Created:  05/28/02  
  
Description:  
=========  
This procedure returns detailed quality data by reel for a given start time, end time, and Line.  
  
INPUTS:  Start Time  
  End Time  
  Production Line Description (without 'TT' prefix)  
  
CALLED BY:  RptPmkgTurnoverQuality.xlt (Excel/VBA Template)  
  
CALLS: None  
  
Rev Change Date Who  What  
=== =========== ====  =====  
0  5/28/02  MW   Original creation  
0.1 6/10/02  CE   Added Order By Prod_Desc,Timestamp to final Select  
0.2 10/23/02  KH   Added Roll Weight to final Select  
1.0 01/28/04  JSJ  - renamed stored procedure to spLocal_RptPmkgTurnoverQuality  
         - added code to put permissions in after the sp is created.  
         - added #ErrorMessage to the code, and added it to the result sets  
         - added parameter checks   
  
1.1 02/05/04 JSJ  - Changed comparisons of Var_Desc vs. hard-coded values so that the comparison    
          is 'GlblDesc=[Global Var_Desc]' in extended-info with a hard-coded value.    
          Note that for this stored procedure to work now, the extended-info information   
          in Variables must be updated accordlingly.  
        - Split the TimeStamp in the result set to Day and Time fields.  
  
1.2 2004-MAR-05 Langdon Davis - Corrected typo where a reference to Roll_G should have been Roll_H.  
  
1.3 2004-MAY-13 Langdon Davis   
  - Added in the Var_Id selection for Tensile MD.  It was missing, but everything  
  else for Tensile MD was in place.  
  
1.4 2004-MAY-26 Matthew Wells   
  - Replaced temp tables with table variables  
  - Added TID to result set  
  - Added result set for limits  
  
1.5 2004-SEP-20 Langdon Davis   
  - Added Wet/Dry Facial Ratio to the results set.  
  - Coalesced the different Wet/Dry _____ Ratio's down to just 'Wet/Dry Tensile Ratio'  
  since for a given product, we will only ever have a value in one of the 3 [Facial,   
  Tissue, or Towel].  
  
1.51 2004-SEP-22 Langdon Davis Changed alias of 'Wet_Dry_Tensile_Ratio' to just 'Wet_Dry_Ratio'.  
  
1.60 2004-Sep-30 Jeff Jaeger   
  - Added the variables Caliper Manual Profile Avg, Caliper Manual Profile Range,   
  and Caliper Profile.  
  - Reindexed the joins to the Tests table in the result sets.  
  
1.61 2004-OCT-04 Langdon Davis   
  Corrected error in the indexing to the Tests table in the result set [Jeff missed  
  updating one number].  
  
1.62 2004-OCT-26 Jeff Jaeger   
  in the insert to @Turnovers, reversed the order of ps1.ProdStatus_Desc  
  and ps2.ProdStatus_Desc    
  
1.7 2004-Nov-16 Jeff Jaeger   
     - updated the insert to @Turnovers, to reindex the assignment of Roll Status.  
     - brought the sp up to standard with Checklist 110804.  
     - added the temp table #RawData, and related code.  This is so that we have   
     translated Histogram variables for the template.  
  
1.71 2005-JAN-18 Langdon Davis   
     Removed some '_' from the results set headers.  
  
1.72 2005-01-24 Jeff Jaeger   
     - removed the case statement from the Limits result set, in favor of simply   
     using the var_desc.  
     - removed the underscores from #RawData field names.  
     - added code to update the field headers in #RawData to reflect local variable   
     names.  could NOT do this with Wet Dry Ratio, because it is not an actual   
     variable.. this field relies on language translation to pull the correct   
     text.  
  
1.73 2005-FEB-04 Langdon Davis   
     Backed out the use of the #RawData table and @SQL to translate the results set as  
     it was inexplicably causing errors to occur when processing the results set that  
     emerged from it [VB shut down in mid-processing].  Also, somehow, it was causing  
     incorrect associations of prod_desc???????  This "fix" is a temporary fix.  Will  
     still need to figure out a way to deliver the business need of the variable  
     descriptions being in local language.  
  
1.74 2005-FEB-18 Langdon Davis   
     Replace Var_Desc in limits results set with the GlblDesc value, using a new  
     variation of the fnLocal_GlblParseInfo function [fnLocal_GlblParseInfoWithSpaces]  
     that maintains case and spacing as is.  This was necessary to address mismatch   
     between the var name in the results results set and the var name in the limits  
     results set.  
  
1.75 2005-04-14 Jeff Jaeger   
     - Undid the changes made in Rev1.73.  Meaning:  put the #RawData temp table   
     with related code back in.  Commented out the @SQL select statement that had   
     replaced use of #RawData.  
     - appended and order by clause to @SQL after it is "translated".  this will   
     force the order of the result set returned to the ADO Recordset in the VBScript   
     to be what we want.  Bear in mind that all the translation function does is   
     build a query string where the various columns are given an alias of whatever   
     their translated names are... so it is still possible to append the order by   
     using the original english.   
     - added object owner specification to object references.   
  
1.76 2005-04-14 Jeff Jaeger   
     - moved the end of the case statement that defines @SQL to include the updates   
     to variable names and the appendage of order by.  this is because we only want   
     the order by clause if there is warning message being returned,   
     such as "Too Many Records" or "No Data".  
  
1.77 2005-APR-20 Langdon Davis  
     Eliminated use of the fnLocal_GlblParseInfoWithSpaces to translate the limits results set  
     names to English and put them back to just var_desc.  This was necessary to match with  
     the translated names in the raw data results set once Jeff did his thing with 1.75.  In  
     other words, undid Rev1.74.  
  
1.78 2005-11-01 Namho Kim -Caliper manual profile chaged to Top Caliper maunal profile.  
  
1.79 2005-12-07 Namho Kim -Quality variable, 'Brightness' is added.  
  
1.80 2006-02-17 Namho Kim -Added Top Caliper Roll A Average, Top Caliper Roll B Average;, Top Caliper Roll A Range,   
   Top Caliper Roll B Range to the quality variables list.  They are from the Perfect Parent Roll production   
   group of the Turnover Quality production unit.  
  
1.81 2006-JAN-30 Langdon Davis  
  - Added 'Lint Wire Side' and 'Lint Fabric side' quality variables.  
  
1.82 2007-SEP-26 Langdon Davis  
  - Added 'Top Caliper Curve Fit Range' and 'Top Caliper Curve Fit Skew' quality variables.  
  
*/  
  
  
CREATE PROCEDURE dbo.spLocal_RptPmkgTurnoverQuality  
--DECLARE  
 @Report_Start_Time  datetime,  
 @Report_End_Time  datetime,  
 @Line    varchar(25),  
 @UserName   varchar(30)  
AS  
  
/* Testing   
SELECT  @Report_Start_Time = '2005-12-06 00:00:00',  
 @Report_End_Time = '2005-12-07 00:00:00',  
 @Line    = 'AZM1',  
 @UserName  = 'ComXClient'  
*/  
  
/************************************************************************************************  
*                                                                                                                               *  
*                                                   Declarations                                                        *  
*                                                                                                                               *  
************************************************************************************************/  
  
DECLARE @Turnovers TABLE (  
 Event_Id int, -- Primary Key,  
 TimeStamp datetime PRIMARY KEY,  
 Prod_Desc varchar(50),  
 Team  varchar(1),  
 Shift  varchar(25),  
 TO_Number varchar(3),  
 TID  varchar(25),  
 Roll_A_Status varchar(50),  
 Roll_B_Status varchar(50),  
 Roll_C_Status varchar(50),  
 Roll_D_Status varchar(50),  
 Roll_E_Status varchar(50),  
 Roll_F_Status varchar(50),  
 Roll_G_Status varchar(50),  
 Roll_H_Status varchar(50)  
)  
  
DECLARE @ErrorMessages TABLE ( ErrMsg varchar(255))  
--/* Rev1.73  
create table dbo.#RawData  
(  
 [T/O Date]   varchar(110),  
 [T/O Time]   varchar(108),  
 [Product_Desc]   varchar(50),  
 [Team]    varchar(10),  
 [Shift]    varchar(25),  
 [TO_Number]   varchar(3),  
 [TID]    varchar(25),  
 [Roll_A_Status]   varchar(100),  
 [Roll_B_Status]   varchar(100),  
 [Roll_C_Status]   varchar(100),  
 [Roll_D_Status]   varchar(100),  
 [Roll_E_Status]   varchar(100),  
 [Roll_F_Status]   varchar(100),  
 [Roll_G_Status]   varchar(100),  
 [Roll_H_Status]   varchar(100),  
 [Basis Weight Manual]  varchar(100),  
 [Caliper Average Roll A] varchar(100),  
 [Caliper Average Roll B] varchar(100),  
 [Caliper Average Roll C] varchar(100),  
 [Caliper Average Roll D] varchar(100),  
 [Caliper Average Roll E] varchar(100),  
 [Caliper Average Roll F] varchar(100),  
 [Caliper Average Roll G] varchar(100),  
 [Caliper Average Roll H] varchar(100),  
 [Caliper Range Roll A]  varchar(100),  
 [Caliper Range Roll B]  varchar(100),  
 [Caliper Range Roll C]  varchar(100),  
 [Caliper Range Roll D]  varchar(100),  
 [Caliper Range Roll E]  varchar(100),  
 [Caliper Range Roll F]  varchar(100),  
 [Caliper Range Roll G]  varchar(100),  
 [Caliper Range Roll H]  varchar(100),  
-- [Caliper Manual Profile Avg] varchar(100),  
-- [Caliper Manual Profile Range] varchar(100),  
-- [Caliper Profile]  varchar(100),  
 [Top Caliper Manual Profile Avg] varchar(100),  
 [Top Caliper Manual Profile Range] varchar(100),  
 [Top Caliper Profile]  varchar(100),  
 [Color A Value]   varchar(100),  
 [Color B Value]   varchar(100),  
 [Color L Value]   varchar(100),  
 [Holes Large Measurement] varchar(100),  
 [Holes Small Count]  varchar(100),  
 [Sink Average]   varchar(100),  
 [Softener Tissue DS SD AVG] varchar(100),  
 [Softener Tissue DS WR AVG] varchar(100),  
 [Softener Tissue TS SD AVG] varchar(100),  
 [Softener Tissue TS WR AVG] varchar(100),  
 [Specks Gross Count]  varchar(100),  
 [Specks Large Count]  varchar(100),  
 [Specks Red Count]  varchar(100),  
 [Specks Small Count]  varchar(100),  
 [Specks Tiny Count]  varchar(100),  
 [Stretch CD]   varchar(100),  
 [Stretch MD]   varchar(100),  
 [Tensile CD]   varchar(100),  
 [Tensile MD]   varchar(100),  
 [Tensile Modulus CD]  varchar(100),  
 [Tensile Modulus GM]  varchar(100),  
 [Tensile Modulus MD]  varchar(100),  
 [Tensile Ratio]   varchar(100),  
 [Tensile Total]   varchar(100),  
 [Web Inspection]  varchar(100),  
 [Wet Burst Average]  varchar(100),  
 [Wet Tensile Average]  varchar(100),  
 [Wet Tensile CD]  varchar(100),  
 [Wet Tensile MD]  varchar(100),  
 [Wet Tensile Ratio]  varchar(100),  
 [Wet Tensile Total]  varchar(100),  
 [Wet Dry Ratio]   varchar(100),  
 [Roll Weight]   varchar(100),  
 [Brightness]   varchar(100), -- Namho Rev1.79  
 [Top Caliper Roll A Average] varchar(100), --2006 Feb 17 Namho Kim Rev1.80  
 [Top Caliper Roll B Average] varchar(100), --2006 Feb 17 Namho Kim Rev1.80  
 [Top Caliper Roll A Range] varchar(100), --2006 Feb 17 Namho Kim Rev1.80  
 [Top Caliper Roll B Range] varchar(100), --2006 Feb 17 Namho Kim Rev1.80  
 [Top Caliper Curve Fit Range] varchar(100),  
 [Top Caliper Curve Fit Skew] varchar(100),  
 [Lint Wire Side] varchar(100),  
 [Lint Fabric Side] varchar(100)  
 )  
  
  
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
  
if (select count(*) from dbo.prod_lines where pl_desc = 'TT ' + ltrim(rtrim(@Line))) = 0   
BEGIN  
 INSERT @ErrorMessages (ErrMsg)  
  VALUES ('@Line is not valid.')  
 GOTO ReturnResultSets  
END  
  
  
Declare @PL_Id      int,  
 @Production_PU_Id    int,  
 @Rolls_PU_Id     int,  
 @Roll_Weight_Var_Id    int,  
 @Quality_PU_Id     int,  
 @Schedule_PU_Id     int,  
 @Extended_Info     varchar(255),   
 @Start_Position     int,  
 @End_Position     int,  
 @Schedule_PU_Str    varchar(255),  
 @Turnover_Status_Desc    varchar(50),  
 @Turnover_Status_Id    int,  
 @Shift_Var_Id     int,  
 @Basis_Weight_Manual_Var_Id    int,  
 @Caliper_Average_Roll_A_Var_Id    int,  
 @Caliper_Average_Roll_B_Var_Id    int,  
 @Caliper_Average_Roll_C_Var_Id    int,  
 @Caliper_Average_Roll_D_Var_Id    int,  
 @Caliper_Average_Roll_E_Var_Id    int,  
 @Caliper_Average_Roll_F_Var_Id    int,  
 @Caliper_Average_Roll_G_Var_Id    int,  
 @Caliper_Average_Roll_H_Var_Id    int,  
 @Caliper_Range_Roll_A_Var_Id    int,  
 @Caliper_Range_Roll_B_Var_Id    int,  
 @Caliper_Range_Roll_C_Var_Id    int,  
 @Caliper_Range_Roll_D_Var_Id    int,  
 @Caliper_Range_Roll_E_Var_Id    int,  
 @Caliper_Range_Roll_F_Var_Id    int,  
 @Caliper_Range_Roll_G_Var_Id    int,  
 @Caliper_Range_Roll_H_Var_Id    int,  
 @Color_A_Value_Var_Id     int,  
 @Color_B_Value_Var_Id     int,  
 @Color_L_Value_Var_Id     int,  
 @Holes_Large_Measurement_Var_Id   int,  
 @Holes_Small_Count_Var_Id    int,  
 @Sink_Average_Var_Id     int,  
 @Softener_Tissue_DS_SD_AVG_Var_Id   int,  
 @Softener_Tissue_DS_WR_AVG_Var_Id   int,  
 @Softener_Tissue_TS_SD_AVG_Var_Id   int,  
 @Softener_Tissue_TS_WR_AVG_Var_Id   int,  
 @Specks_Gross_Count_Var_Id    int,  
 @Specks_Large_Count_Var_Id    int,  
 @Specks_Red_Count_Var_Id    int,  
 @Specks_Small_Count_Var_Id    int,  
 @Specks_Tiny_Count_Var_Id    int,  
 @Stretch_CD_Var_Id     int,  
 @Stretch_MD_Var_Id     int,  
 @Tensile_CD_Var_Id     int,  
 @Tensile_MD_Var_Id     int,  
 @Tensile_Modulus_CD_Var_Id    int,  
 @Tensile_Modulus_GM_Var_Id    int,  
 @Tensile_Modulus_MD_Var_Id    int,  
 @Tensile_Ratio_Var_Id     int,  
 @Tensile_Total_Var_Id     int ,  
 @Web_Inspection_Var_Id     int,  
 @Wet_Burst_Average_Var_Id    int,  
 @Wet_Tensile_Average_Var_Id    int,  
 @Wet_Tensile_CD_Var_Id     int,  
 @Wet_Tensile_MD_Var_Id     int,  
 @Wet_Tensile_Ratio_Var_Id    int,  
 @Wet_Tensile_Total_Var_Id    int,  
 @Wet_Dry_Tissue_Ratio_Var_Id    int,  
 @Wet_Dry_Towel_Ratio_Var_Id    int,  
 @Wet_Dry_Facial_Ratio_Var_Id    int,  
-- added by JSJ for Rev1.6  
 @CaliperManualProfileAvg_Var_ID   int,  
 @CaliperManualProfileRange_Var_ID  int,  
 @CaliperProfile_Var_ID    int,  
-- @TopCaliperManualProfileAvg_Var_ID  int,  
-- @TopCaliperManualProfileRange_Var_ID  int,  
 @TopCaliperRollAAverage_Var_ID   int, --2006 Feb 17 Namho Kim Rev1.80  
 @TopCaliperRollBAverage_Var_ID   int, --2006 Feb 17 Namho Kim Rev1.80  
 @TopCaliperRollARange_Var_ID   int, --2006 Feb 17 Namho Kim Rev1.80  
 @TopCaliperRollBRange_Var_ID   int, --2006 Feb 17 Namho Kim Rev1.80  
 @TopCaliperCurveFitRange_Var_ID   int,  
 @TopCaliperCurveFitSkew_Var_ID   int,  
 @LanguageId     integer,  
 @UserId      integer,  
 @LanguageParmId     integer,  
 @NoDataMsg      varchar(50),  
 @TooMuchDataMsg     varchar(50),  
 @SQL       varchar(8000),  
 @Brightness_Var_ID    int, --Namho Rev1.79  
 @LintWireSide_Var_ID    int,  
 @LintFabricSide_Var_ID   int  
  
  
/************************************************************************************************  
*                                              Initialization                                                               *  
************************************************************************************************/  
/* Initialization */  
Select @Turnover_Status_Desc = 'Complete'  
  
  
/***********************************************************************************************  
*     Get Language Info  
************************************************************************************************/  
  
select   @LanguageParmID  = 8,  
@LanguageId  = NULL  
  
SELECT @UserId = User_Id  
FROM dbo.Users  
WHERE UserName = @UserName  
  
SELECT @LanguageId = CASE   
WHEN isnumeric(ltrim(rtrim(Value))) = 1   
THEN convert(float, ltrim(rtrim(Value)))  
    ELSE NULL  
    END  
FROM dbo.User_Parameters  
WHERE User_Id = @UserId  
 AND Parm_Id = @LanguageParmId  
  
  
-- updated for efficiency 061004  
IF @LanguageId IS NULL  
  
  SELECT @LanguageId = CASE   
WHEN isnumeric(ltrim(rtrim(Value))) = 1   
THEN convert(float, ltrim(rtrim(Value)))  
     ELSE NULL  
     END  
  FROM dbo.Site_Parameters  
  WHERE Parm_Id = @LanguageParmId  
  
-- updated for efficiency 061004  
IF @LanguageId IS NULL  
  
  SELECT @LanguageId = 0  
  
  
select @NoDataMsg = GBDB.dbo.fnLocal_GlblTranslation('NO DATA meets the given criteria', @LanguageId)  
select @TooMuchDataMsg = GBDB.dbo.fnLocal_GlblTranslation('There are more results than can be displayed', @LanguageId)  
  
  
/************************************************************************************************  
*                                     Get Configuration                                                               *  
************************************************************************************************/  
/* Get Configuration */  
If @Report_End_Time >= getdate()  
     Select @Report_End_Time = Dateadd(mi, -5, getdate())  
  
Select @PL_Id = PL_Id  
From dbo.Prod_Lines  
Where PL_Desc = 'TT ' + @Line  
  
Select @Production_PU_Id = PU_Id  
From dbo.Prod_Units  
Where PL_Id = @PL_Id And PU_Desc = @Line + ' Production'  
  
Select @Quality_PU_Id = PU_Id  
From dbo.Prod_Units  
Where PL_Id = @PL_Id And PU_Desc = @Line + ' Turnover Quality'  
  
Select @Rolls_PU_Id = PU_Id  
From dbo.Prod_Units  
Where PL_Id = @PL_Id And PU_Desc = @Line + ' Rolls'  
  
Select @Turnover_Status_Id = ProdStatus_Id  
From dbo.Production_Status  
Where ProdStatus_Desc = @Turnover_Status_Desc  
  
Select @Shift_Var_Id = Var_Id  
From dbo.Variables  
Where PU_Id = @Production_PU_Id   
and charindex(lower('GlblDesc=Shift Reel;'),lower(coalesce(extended_info,''))) > 0  
  
/* Get schedule unit */  
Select @Extended_Info = Extended_Info  
From dbo.Prod_Units  
Where PU_Id = @Production_PU_Id  
  
Select @Start_Position = charindex('ScheduleUnit=', @Extended_Info, 0) + 13  
Select @End_Position = charindex(';', @Extended_Info, @Start_Position)  
If @End_Position = 0  
     Select @End_Position = @Start_Position + 10  
Select @Schedule_PU_Str = substring(@Extended_Info, @Start_Position, @End_Position-@Start_Position)  
If IsNumeric(@Schedule_PU_Str) = 1  
     Select @Schedule_PU_Id = convert(int, @Schedule_PU_Str)  
  
/* Get quality variables */  
  
Select @Basis_Weight_Manual_Var_Id = Var_Id   
From dbo.Variables   
Where PU_Id = @Quality_PU_Id   
and charindex(lower('GlblDesc=Basis Weight Manual;'),lower(coalesce(extended_info,''))) > 0  
  
Select @Roll_Weight_Var_Id = Var_Id   
From dbo.Variables   
Where PU_Id = @Rolls_PU_Id   
and charindex(lower('GlblDesc=Roll Weight Official;'),lower(coalesce(extended_info,''))) > 0  
  
Select @Caliper_Average_Roll_A_Var_Id = Var_Id   
From dbo.Variables   
Where PU_Id = @Quality_PU_Id   
and charindex(lower('GlblDesc=Caliper Average Roll A;'),lower(coalesce(extended_info,''))) > 0  
  
Select @Caliper_Average_Roll_B_Var_Id = Var_Id   
From dbo.Variables   
Where PU_Id = @Quality_PU_Id   
and charindex(lower('GlblDesc=Caliper Average Roll B;'),lower(coalesce(extended_info,''))) > 0  
  
Select @Caliper_Average_Roll_C_Var_Id = Var_Id   
From dbo.Variables   
Where PU_Id = @Quality_PU_Id   
and charindex(lower('GlblDesc=Caliper Average Roll C;'),lower(coalesce(extended_info,''))) > 0  
  
Select @Caliper_Average_Roll_D_Var_Id = Var_Id   
From dbo.Variables   
Where PU_Id = @Quality_PU_Id   
and charindex(lower('GlblDesc=Caliper Average Roll D;'),lower(coalesce(extended_info,''))) > 0  
  
Select @Caliper_Average_Roll_E_Var_Id = Var_Id   
From dbo.Variables   
Where PU_Id = @Quality_PU_Id   
and charindex(lower('GlblDesc=Caliper Average Roll E;'),lower(coalesce(extended_info,''))) > 0  
  
Select @Caliper_Average_Roll_F_Var_Id = Var_Id   
From dbo.Variables   
Where PU_Id = @Quality_PU_Id   
and charindex(lower('GlblDesc=Caliper Average Roll F;'),lower(coalesce(extended_info,''))) > 0  
  
Select @Caliper_Average_Roll_G_Var_Id = Var_Id   
From dbo.Variables   
Where PU_Id = @Quality_PU_Id   
and charindex(lower('GlblDesc=Caliper Average Roll G;'),lower(coalesce(extended_info,''))) > 0  
  
Select @Caliper_Average_Roll_H_Var_Id = Var_Id   
From dbo.Variables   
Where PU_Id = @Quality_PU_Id   
and charindex(lower('GlblDesc=Caliper Average Roll H;'),lower(coalesce(extended_info,''))) > 0  
  
Select @Caliper_Range_Roll_A_Var_Id = Var_Id   
From dbo.Variables   
Where PU_Id = @Quality_PU_Id   
and charindex(lower('GlblDesc=Caliper Range Roll A;'),lower(coalesce(extended_info,''))) > 0  
  
Select @Caliper_Range_Roll_B_Var_Id = Var_Id   
From dbo.Variables   
Where PU_Id = @Quality_PU_Id   
and charindex(lower('GlblDesc=Caliper Range Roll B;'),lower(coalesce(extended_info,''))) > 0  
  
Select @Caliper_Range_Roll_C_Var_Id = Var_Id   
From dbo.Variables   
Where PU_Id = @Quality_PU_Id   
and charindex(lower('GlblDesc=Caliper Range Roll C;'),lower(coalesce(extended_info,''))) > 0  
  
Select @Caliper_Range_Roll_D_Var_Id = Var_Id   
From dbo.Variables   
Where PU_Id = @Quality_PU_Id   
and charindex(lower('GlblDesc=Caliper Range Roll D;'),lower(coalesce(extended_info,''))) > 0  
  
Select @Caliper_Range_Roll_E_Var_Id = Var_Id   
From dbo.Variables   
Where PU_Id = @Quality_PU_Id   
and charindex(lower('GlblDesc=Caliper Range Roll E;'),lower(coalesce(extended_info,''))) > 0  
  
Select @Caliper_Range_Roll_F_Var_Id = Var_Id   
From dbo.Variables   
Where PU_Id = @Quality_PU_Id   
and charindex(lower('GlblDesc=Caliper Range Roll F;'),lower(coalesce(extended_info,''))) > 0  
  
Select @Caliper_Range_Roll_G_Var_Id = Var_Id   
From dbo.Variables   
Where PU_Id = @Quality_PU_Id   
and charindex(lower('GlblDesc=Caliper Range Roll G;'),lower(coalesce(extended_info,''))) > 0  
  
Select @Caliper_Range_Roll_H_Var_Id = Var_Id   
From dbo.Variables   
Where PU_Id = @Quality_PU_Id   
and charindex(lower('GlblDesc=Caliper Range Roll H;'),lower(coalesce(extended_info,''))) > 0  
  
Select @Color_A_Value_Var_Id = Var_Id   
From dbo.Variables   
Where PU_Id = @Quality_PU_Id   
and charindex(lower('GlblDesc=Color A Value;'),lower(coalesce(extended_info,''))) > 0  
  
Select @Color_B_Value_Var_Id = Var_Id   
From dbo.Variables   
Where PU_Id = @Quality_PU_Id   
and charindex(lower('GlblDesc=Color B Value;'),lower(coalesce(extended_info,''))) > 0  
  
Select @Color_L_Value_Var_Id = Var_Id   
From dbo.Variables   
Where PU_Id = @Quality_PU_Id   
and charindex(lower('GlblDesc=Color L Value;'),lower(coalesce(extended_info,''))) > 0  
  
Select @Holes_Large_Measurement_Var_Id = Var_Id   
From dbo.Variables   
Where PU_Id = @Quality_PU_Id   
and charindex(lower('GlblDesc=Holes Large Measurement;'),lower(coalesce(extended_info,''))) > 0  
  
Select @Holes_Small_Count_Var_Id = Var_Id   
From dbo.Variables   
Where PU_Id = @Quality_PU_Id   
and charindex(lower('GlblDesc=Holes Small Count;'),lower(coalesce(extended_info,''))) > 0  
  
Select @Sink_Average_Var_Id = Var_Id   
From dbo.Variables   
Where PU_Id = @Quality_PU_Id   
and charindex(lower('GlblDesc=Sink Average;'),lower(coalesce(extended_info,''))) > 0  
  
Select @Softener_Tissue_DS_SD_AVG_Var_Id = Var_Id   
From dbo.Variables   
Where PU_Id = @Quality_PU_Id   
and charindex(lower('GlblDesc=Softener Tissue DS SD/AVG;'),lower(coalesce(extended_info,''))) > 0  
  
Select @Softener_Tissue_DS_WR_AVG_Var_Id = Var_Id   
From dbo.Variables   
Where PU_Id = @Quality_PU_Id   
and charindex(lower('GlblDesc=Softener Tissue DS WR/AVG;'),lower(coalesce(extended_info,''))) > 0  
  
Select @Softener_Tissue_TS_SD_AVG_Var_Id = Var_Id   
From dbo.Variables   
Where PU_Id = @Quality_PU_Id   
and charindex(lower('GlblDesc=Softener Tissue TS SD/AVG;'),lower(coalesce(extended_info,''))) > 0  
  
Select @Softener_Tissue_TS_WR_AVG_Var_Id = Var_Id   
From dbo.Variables   
Where PU_Id = @Quality_PU_Id   
and charindex(lower('GlblDesc=Softener Tissue TS WR/AVG;'),lower(coalesce(extended_info,''))) > 0  
  
Select @Specks_Gross_Count_Var_Id = Var_Id   
From dbo.Variables   
Where PU_Id = @Quality_PU_Id   
and charindex(lower('GlblDesc=Specks Gross Count;'),lower(coalesce(extended_info,''))) > 0  
  
Select @Specks_Large_Count_Var_Id = Var_Id   
From dbo.Variables   
Where PU_Id = @Quality_PU_Id   
and charindex(lower('GlblDesc=Specks Large Count;'),lower(coalesce(extended_info,''))) > 0  
  
Select @Specks_Red_Count_Var_Id = Var_Id   
From dbo.Variables Where PU_Id = @Quality_PU_Id   
and charindex(lower('GlblDesc=Specks Red Count;'),lower(coalesce(extended_info,''))) > 0  
  
Select @Specks_Small_Count_Var_Id = Var_Id   
From dbo.Variables   
Where PU_Id = @Quality_PU_Id   
and charindex(lower('GlblDesc=Specks Small Count;'),lower(coalesce(extended_info,''))) > 0  
  
Select @Specks_Tiny_Count_Var_Id = Var_Id   
From dbo.Variables   
Where PU_Id = @Quality_PU_Id   
and charindex(lower('GlblDesc=Specks Tiny Count;'),lower(coalesce(extended_info,''))) > 0  
  
Select @Stretch_CD_Var_Id = Var_Id   
From dbo.Variables   
Where PU_Id = @Quality_PU_Id   
and charindex(lower('GlblDesc=Stretch CD;'),lower(coalesce(extended_info,''))) > 0  
  
Select @Stretch_MD_Var_Id = Var_Id   
From dbo.Variables   
Where PU_Id = @Quality_PU_Id   
and charindex(lower('GlblDesc=Stretch MD;'),lower(coalesce(extended_info,''))) > 0  
  
Select @Tensile_CD_Var_Id = Var_Id   
From dbo.Variables   
Where PU_Id = @Quality_PU_Id   
and charindex(lower('GlblDesc=Tensile CD;'),lower(coalesce(extended_info,''))) > 0  
  
Select @Tensile_MD_Var_Id = Var_Id   
From dbo.Variables   
Where PU_Id = @Quality_PU_Id   
and charindex(lower('GlblDesc=Tensile MD;'),lower(coalesce(extended_info,''))) > 0  
  
Select @Tensile_Modulus_CD_Var_Id = Var_Id   
From dbo.Variables   
Where PU_Id = @Quality_PU_Id   
and charindex(lower('GlblDesc=Tensile Modulus CD;'),lower(coalesce(extended_info,''))) > 0  
  
Select @Tensile_Modulus_GM_Var_Id = Var_Id   
From dbo.Variables Where PU_Id = @Quality_PU_Id   
and charindex(lower('GlblDesc=Tensile Modulus GM;'),lower(coalesce(extended_info,''))) > 0  
  
Select @Tensile_Modulus_MD_Var_Id = Var_Id   
From dbo.Variables   
Where PU_Id = @Quality_PU_Id   
and charindex(lower('GlblDesc=Tensile Modulus MD;'),lower(coalesce(extended_info,''))) > 0  
  
Select @Tensile_Ratio_Var_Id = Var_Id   
From dbo.Variables   
Where PU_Id = @Quality_PU_Id   
and charindex(lower('GlblDesc=Tensile Ratio;'),lower(coalesce(extended_info,''))) > 0  
  
Select @Tensile_Total_Var_Id = Var_Id   
From dbo.Variables   
Where PU_Id = @Quality_PU_Id   
and charindex(lower('GlblDesc=Tensile Total;'),lower(coalesce(extended_info,''))) > 0  
  
Select @Web_Inspection_Var_Id = Var_Id   
From dbo.Variables   
Where PU_Id = @Quality_PU_Id   
and charindex(lower('GlblDesc=Web Inspection;'),lower(coalesce(extended_info,''))) > 0  
  
Select @Wet_Burst_Average_Var_Id = Var_Id   
From dbo.Variables   
Where PU_Id = @Quality_PU_Id   
and charindex(lower('GlblDesc=Wet Burst Average;'),lower(coalesce(extended_info,''))) > 0  
  
Select @Wet_Tensile_Average_Var_Id = Var_Id   
From dbo.Variables   
Where PU_Id = @Quality_PU_Id   
and charindex(lower('GlblDesc=Wet Tensile Average;'),lower(coalesce(extended_info,''))) > 0  
  
Select @Wet_Tensile_CD_Var_Id = Var_Id   
From dbo.Variables   
Where PU_Id = @Quality_PU_Id   
and charindex(lower('GlblDesc=Wet Tensile CD;'),lower(coalesce(extended_info,''))) > 0  
  
Select @Wet_Tensile_MD_Var_Id = Var_Id   
From dbo.Variables   
Where PU_Id = @Quality_PU_Id   
and charindex(lower('GlblDesc=Wet Tensile MD;'),lower(coalesce(extended_info,''))) > 0  
  
Select @Wet_Tensile_Ratio_Var_Id = Var_Id   
From dbo.Variables   
Where PU_Id = @Quality_PU_Id   
and charindex(lower('GlblDesc=Wet Tensile Ratio;'),lower(coalesce(extended_info,''))) > 0  
  
Select @Wet_Tensile_Total_Var_Id = Var_Id   
From dbo.Variables   
Where PU_Id = @Quality_PU_Id   
and charindex(lower('GlblDesc=Wet Tensile Total;'),lower(coalesce(extended_info,''))) > 0  
  
Select @Wet_Dry_Tissue_Ratio_Var_Id = Var_Id   
From dbo.Variables   
Where PU_Id = @Quality_PU_Id   
and charindex(lower('GlblDesc=Wet/Dry Tissue Ratio;'),lower(coalesce(extended_info,''))) > 0  
  
Select @Wet_Dry_Towel_Ratio_Var_Id = Var_Id   
From dbo.Variables   
Where PU_Id = @Quality_PU_Id   
and charindex(lower('GlblDesc=Wet/Dry Towel Ratio;'),lower(coalesce(extended_info,''))) > 0  
  
Select @Wet_Dry_Facial_Ratio_Var_Id = Var_Id   
From dbo.Variables   
Where PU_Id = @Quality_PU_Id   
and charindex(lower('GlblDesc=Wet/Dry Facial Ratio;'),lower(coalesce(extended_info,''))) > 0  
  
Select @CaliperManualProfileAvg_Var_ID = Var_Id   
From dbo.Variables   
Where PU_Id = @Quality_PU_Id   
and (charindex(lower('GlblDesc=Caliper Manual Profile Avg;'),lower(coalesce(extended_info,''))) > 0 or charindex(lower('GlblDesc=Top Caliper Manual Profile Avg;'),lower(coalesce(extended_info,''))) > 0)  
  
Select @CaliperManualProfileRange_Var_ID = Var_Id   
From dbo.Variables   
Where PU_Id = @Quality_PU_Id   
and (charindex(lower('GlblDesc=Caliper Manual Profile Range;'),lower(coalesce(extended_info,''))) > 0 or charindex(lower('GlblDesc=Top Caliper Manual Profile Range;'),lower(coalesce(extended_info,''))) > 0)  
  
Select @CaliperProfile_Var_ID = Var_Id   
From dbo.Variables   
Where PU_Id = @Quality_PU_Id   
and (charindex(lower('GlblDesc=Caliper Profile;'),lower(coalesce(extended_info,''))) > 0 or charindex(lower('GlblDesc=Top Caliper Profile;'),lower(coalesce(extended_info,''))) > 0)  
  
--2006 Feb 17 Namho Kim Rev7.80  
  
Select @TopCaliperRollAAverage_Var_Id = Var_Id   
From dbo.Variables   
Where PU_Id = @Quality_PU_Id   
and charindex(lower('GlblDesc=Top Caliper Roll A Average;'),lower(coalesce(extended_info,''))) > 0  
  
Select @TopCaliperRollBAverage_Var_Id = Var_Id   
From dbo.Variables   
Where PU_Id = @Quality_PU_Id   
and charindex(lower('GlblDesc=Top Caliper Roll B Average;'),lower(coalesce(extended_info,''))) > 0  
  
Select @TopCaliperRollARange_Var_Id = Var_Id   
From dbo.Variables   
Where PU_Id = @Quality_PU_Id   
and charindex(lower('GlblDesc=Top Caliper Roll A Range;'),lower(coalesce(extended_info,''))) > 0  
  
  
Select @TopCaliperRollBRange_Var_Id = Var_Id   
From dbo.Variables   
Where PU_Id = @Quality_PU_Id   
and charindex(lower('GlblDesc=Top Caliper Roll B Range;'),lower(coalesce(extended_info,''))) > 0  
  
Select @TopCaliperCurveFitRange_Var_Id = Var_Id   
From dbo.Variables   
Where PU_Id = @Quality_PU_Id   
and charindex(lower('GlblDesc=Top Caliper Curve Fit Range;'),lower(coalesce(extended_info,''))) > 0  
  
Select @TopCaliperCurveFitSkew_Var_Id = Var_Id   
From dbo.Variables   
Where PU_Id = @Quality_PU_Id   
and charindex(lower('GlblDesc=Top Caliper Curve Fit Skew;'),lower(coalesce(extended_info,''))) > 0  
  
--Namho Rev1.79  
select @Brightness_var_ID=Var_id  
from dbo.Variables  
Where PU_Id = @Quality_PU_Id   
and charindex(lower('GlblDesc=Brightness;'),lower(coalesce(extended_info,''))) > 0  
  
select @LintWireSide_Var_ID=Var_id  
from dbo.Variables  
Where PU_Id = @Quality_PU_Id   
and charindex(lower('GlblDesc=Lint Wire Side;'),lower(coalesce(extended_info,''))) > 0  
  
select @LintFabricSide_Var_ID=Var_id  
from dbo.Variables  
Where PU_Id = @Quality_PU_Id   
and charindex(lower('GlblDesc=Lint Fabric Side;'),lower(coalesce(extended_info,''))) > 0  
/************************************************************************************************  
*                                                                                                                               *  
*                                                     Get Turnovers                                                   *  
*                                                                                                                               *  
************************************************************************************************/  
Insert Into @Turnovers (Event_Id,   
   TimeStamp,   
   Prod_Desc,   
   Team,  
   Shift,  
   TO_Number,  
   TID,  
   Roll_A_Status,   
   Roll_B_Status,   
   Roll_C_Status,   
   Roll_D_Status,   
   Roll_E_Status,   
   Roll_F_Status,   
   Roll_G_Status,   
   Roll_H_Status)  
Select  e.Event_Id,  
 e.TimeStamp,  
 p.Prod_Desc,  
 substring(e.Event_Num, 7, 1),  
 t.Result,  
 right(e.Event_Num, 3),  
 e.Event_Num,  
 --Roll_A_Status,  
 case  
  when ps8.ProdStatus_Desc is not null   
  then ps8.ProdStatus_Desc  
  when ps7.ProdStatus_Desc is not null   
  then ps7.ProdStatus_Desc  
  when ps6.ProdStatus_Desc is not null   
  then ps6.ProdStatus_Desc  
  when ps5.ProdStatus_Desc is not null   
  then ps5.ProdStatus_Desc  
  when ps4.ProdStatus_Desc is not null   
  then ps4.ProdStatus_Desc  
  when ps3.ProdStatus_Desc is not null   
  then ps3.ProdStatus_Desc  
  when ps2.ProdStatus_Desc is not null   
  then ps2.ProdStatus_Desc  
  when ps1.ProdStatus_Desc is not null   
  then ps1.ProdStatus_Desc  
  else null   
 end As Roll_A_Status,  
 --Roll_B_Status,  
 case  
  when ps8.ProdStatus_Desc is not null   
  then ps7.ProdStatus_Desc  
  when ps7.ProdStatus_Desc is not null   
  then ps6.ProdStatus_Desc  
  when ps6.ProdStatus_Desc is not null   
  then ps5.ProdStatus_Desc  
  when ps5.ProdStatus_Desc is not null   
  then ps4.ProdStatus_Desc  
  when ps4.ProdStatus_Desc is not null   
  then ps3.ProdStatus_Desc  
  when ps3.ProdStatus_Desc is not null   
  then ps2.ProdStatus_Desc  
  when ps2.ProdStatus_Desc is not null   
  then ps1.ProdStatus_Desc  
  else null   
 end As Roll_B_Status,  
 --Roll_C_Status,  
 case  
  when ps8.ProdStatus_Desc is not null   
  then ps6.ProdStatus_Desc  
  when ps7.ProdStatus_Desc is not null   
  then ps5.ProdStatus_Desc  
  when ps6.ProdStatus_Desc is not null   
  then ps4.ProdStatus_Desc  
  when ps5.ProdStatus_Desc is not null   
  then ps3.ProdStatus_Desc  
  when ps4.ProdStatus_Desc is not null   
  then ps2.ProdStatus_Desc  
  when ps3.ProdStatus_Desc is not null   
  then ps1.ProdStatus_Desc  
  else null   
 end As Roll_C_Status,  
 --Roll_D_Status,  
 case  
  when ps8.ProdStatus_Desc is not null   
  then ps5.ProdStatus_Desc  
  when ps7.ProdStatus_Desc is not null   
  then ps4.ProdStatus_Desc  
  when ps6.ProdStatus_Desc is not null   
  then ps3.ProdStatus_Desc  
  when ps5.ProdStatus_Desc is not null   
  then ps2.ProdStatus_Desc  
  when ps4.ProdStatus_Desc is not null   
  then ps1.ProdStatus_Desc  
  else null   
 end As Roll_D_Status,  
 --Roll_E_Status,  
 case  
  when ps8.ProdStatus_Desc is not null   
  then ps4.ProdStatus_Desc  
  when ps7.ProdStatus_Desc is not null   
  then ps3.ProdStatus_Desc  
  when ps6.ProdStatus_Desc is not null   
  then ps2.ProdStatus_Desc  
  when ps5.ProdStatus_Desc is not null   
  then ps1.ProdStatus_Desc  
  else null   
 end As Roll_E_Status,  
 --Roll_F_Status,  
 case  
  when ps8.ProdStatus_Desc is not null   
  then ps3.ProdStatus_Desc  
  when ps7.ProdStatus_Desc is not null   
  then ps2.ProdStatus_Desc  
  when ps6.ProdStatus_Desc is not null   
  then ps1.ProdStatus_Desc  
  else null   
 end As Roll_F_Status,  
 --Roll_G_Status,  
 case  
  when ps8.ProdStatus_Desc is not null   
  then ps2.ProdStatus_Desc  
  when ps7.ProdStatus_Desc is not null   
  then ps1.ProdStatus_Desc  
  else null   
 end As Roll_G_Status,  
 --Roll_H_Status   
 case  
  when ps8.ProdStatus_Desc is not null   
  then ps1.ProdStatus_Desc  
  else null   
 end As Roll_H_Status  
   
From dbo.Events e  
     Left Join dbo.Production_Starts ps On e.TimeStamp >= ps.Start_Time   
 And (e.TimeStamp < ps.End_Time Or ps.End_Time Is Null)   
 And ps.PU_Id = @Production_PU_Id  
     Left Join dbo.Products p On ps.Prod_Id = p.Prod_Id  
     Left Join dbo.tests t On e.TimeStamp = t.Result_On   
 And t.Var_Id = @Shift_Var_Id   
 And Result Is Not Null  
     Left Join dbo.Events re1 On re1.PU_Id = @Rolls_PU_Id   
 And re1.TimeStamp = e.TimeStamp  
     Left Join dbo.Production_Status ps1 On re1.Event_Status = ps1.ProdStatus_Id  
     Left Join dbo.Events re2 On re2.PU_Id = @Rolls_PU_Id   
 And re2.TimeStamp = DateAdd(s, -1, e.TimeStamp)  
     Left Join dbo.Production_Status ps2 On re2.Event_Status = ps2.ProdStatus_Id  
     Left Join dbo.Events re3 On re3.PU_Id = @Rolls_PU_Id   
 And re3.TimeStamp = DateAdd(s, -2, e.TimeStamp)  
     Left Join dbo.Production_Status ps3 On re3.Event_Status = ps3.ProdStatus_Id  
     Left Join dbo.Events re4 On re4.PU_Id = @Rolls_PU_Id   
 And re4.TimeStamp = DateAdd(s, -3, e.TimeStamp)  
     Left Join dbo.Production_Status ps4 On re4.Event_Status = ps4.ProdStatus_Id  
     Left Join dbo.Events re5 On re5.PU_Id = @Rolls_PU_Id   
 And re5.TimeStamp = DateAdd(s, -4, e.TimeStamp)  
     Left Join dbo.Production_Status ps5 On re5.Event_Status = ps5.ProdStatus_Id  
     Left Join dbo.Events re6 On re6.PU_Id = @Rolls_PU_Id   
 And re6.TimeStamp = DateAdd(s, -5, e.TimeStamp)  
     Left Join dbo.Production_Status ps6 On re6.Event_Status = ps6.ProdStatus_Id  
     Left Join dbo.Events re7 On re7.PU_Id = @Rolls_PU_Id   
 And re7.TimeStamp = DateAdd(s, -6, e.TimeStamp)  
     Left Join dbo.Production_Status ps7 On re7.Event_Status = ps7.ProdStatus_Id  
     Left Join dbo.Events re8 On re8.PU_Id = @Rolls_PU_Id   
 And re8.TimeStamp = DateAdd(s, -7, e.TimeStamp)  
     Left Join dbo.Production_Status ps8 On re8.Event_Status = ps8.ProdStatus_Id  
Where e.PU_Id = @Production_PU_Id   
And e.TimeStamp >= @Report_Start_Time   
And e.TimeStamp < @Report_End_Time   
And e.Event_Status = @Turnover_Status_Id  
  
  
--select * from @Turnovers  
  
/************************************************************************************************  
*                                                                                                                               *  
*                                                     Get Quality Data                                                *  
*                                                                                                                               *  
************************************************************************************************/  
  
ReturnResultSets:  
  
if (select count(*) from @ErrorMessages) > 0   
  
 select * from @ErrorMessages  
  
else  
  
begin  
  
 select * from @ErrorMessages  
  
  
-- Raw Data result set  
insert dbo.#RawData  --Rev1.73  
Select  convert(varchar,e.TimeStamp,110) [T/O Date],  
 convert(varchar,e.TimeStamp,108) [T/O Time],  
 e.Prod_Desc,  
 e.Team,  
 e.Shift,  
 e.TO_Number,  
 e.TID,  
 e.Roll_A_Status,  
 e.Roll_B_Status,  
 e.Roll_C_Status,  
 e.Roll_D_Status,  
 e.Roll_E_Status,  
 e.Roll_F_Status,  
 e.Roll_G_Status,  
 e.Roll_H_Status,  
 t1.Result As [Basis Weight Manual],  
 t2.Result As [Caliper Average Roll A],  
 t3.Result As [Caliper Average Roll B],  
 t4.Result As [Caliper Average Roll C],  
 t5.Result As [Caliper Average Roll D],  
 t6.Result As [Caliper Average Roll E],  
 t7.Result As [Caliper Average Roll F],  
 t8.Result As [Caliper Average Roll G],  
 t9.Result As [Caliper Average Roll H],  
 t10.Result As [Caliper Range Roll A],  
 t11.Result As [Caliper Range Roll B],  
 t12.Result As [Caliper Range Roll C],  
 t13.Result As [Caliper Range Roll D],  
 t14.Result As [Caliper Range Roll E],  
 t15.Result As [Caliper Range Roll F],  
 t16.Result As [Caliper Range Roll G],  
 t17.Result As [Caliper Range Roll H],  
 t18.Result AS [Top Caliper Manual Profile Avg],  
 t19.Result AS [Top Caliper Manual Profile Range],  
 t20.Result AS [Top Caliper Profile],  
 t21.Result As [Color A Value],  
 t22.Result As [Color B Value],  
 t23.Result As [Color L Value],  
 t24.Result As [Holes Large Measurement],  
 t25.Result As [Holes Small Count],  
 t26.Result As [Sink Average],  
 t27.Result As [Softener Tissue DS SD AVG],  
 t28.Result As [Softener Tissue DS WR AVG],  
 t29.Result As [Softener Tissue TS SD AVG],  
 t30.Result As [Softener Tissue TS WR AVG],  
 t31.Result As [Specks Gross Count],  
 t32.Result As [Specks Large Count],  
 t33.Result As [Specks Red Count],  
 t34.Result As [Specks Small Count],  
 t35.Result As [Specks Tiny Count],  
 t36.Result As [Stretch CD],  
 t37.Result As [Stretch MD],  
 t38.Result As [Tensile CD],  
 t39.Result As [Tensile MD],  
 t40.Result As [Tensile Modulus CD],  
 t41.Result As [Tensile Modulus GM],  
 t42.Result As [Tensile Modulus MD],  
 t43.Result As [Tensile Ratio],  
 t44.Result As [Tensile Total],  
 t45.Result As [Web Inspection],  
 t46.Result As [Wet Burst Average],  
 t47.Result As [Wet Tensile Average],  
 t48.Result As [Wet Tensile CD],  
 t49.Result As [Wet Tensile MD],  
 t50.Result As [Wet Tensile Ratio],  
 t51.Result As [Wet Tensile Total],  
 COALESCE(t52.Result, t53.Result,t54.Result) As [Wet Dry Ratio],  
 t55.Result As [Roll Weight],  
 t56.Result As [Brightness], --Namho Rev1.79  
 t57.Result AS [Top Caliper Roll A Average],  
 t58.Result AS [Top Caliper Roll B Average],  
 t59.Result AS [Top Caliper Roll A Range],  
 t60.Result AS [Top Caliper Roll B Range],  
 t61.Result AS [Top Caliper Curve Fit Range],  
 t62.Result AS [Top Caliper Curve Fit Skew],  
 t63.Result AS [Lint Wire Side],  
 t64.Result AS [Lint Fabric Side]  
  
-- we need to create a #tests temp table and put the data into it, so that we don't have to join to the real tests tables  
-- so many times during this select statement...  
From @Turnovers e  
     Left Join dbo.tests t1 On t1.Result_On = e.TimeStamp   
 And t1.Var_Id = @Basis_Weight_Manual_Var_Id   
 And t1.Result Is Not Null  
     Left Join dbo.tests t2 On t2.Result_On = e.TimeStamp   
 And t2.Var_Id = @Caliper_Average_Roll_A_Var_Id   
 And t2.Result Is Not Null  
     Left Join dbo.tests t3 On t3.Result_On = e.TimeStamp   
 And t3.Var_Id = @Caliper_Average_Roll_B_Var_Id   
 And t3.Result Is Not Null  
     Left Join dbo.tests t4 On t4.Result_On = e.TimeStamp   
 And t4.Var_Id = @Caliper_Average_Roll_C_Var_Id   
 And t4.Result Is Not Null  
     Left Join dbo.tests t5 On t5.Result_On = e.TimeStamp   
 And t5.Var_Id = @Caliper_Average_Roll_D_Var_Id   
 And t5.Result Is Not Null  
     Left Join dbo.tests t6 On t6.Result_On = e.TimeStamp   
 And t6.Var_Id = @Caliper_Average_Roll_E_Var_Id   
 And t6.Result Is Not Null  
     Left Join dbo.tests t7 On t7.Result_On = e.TimeStamp   
 And t7.Var_Id = @Caliper_Average_Roll_F_Var_Id   
 And t7.Result Is Not Null  
     Left Join dbo.tests t8 On t8.Result_On = e.TimeStamp   
 And t8.Var_Id = @Caliper_Average_Roll_G_Var_Id   
 And t8.Result Is Not Null  
     Left Join dbo.tests t9 On t9.Result_On = e.TimeStamp   
 And t9.Var_Id = @Caliper_Average_Roll_H_Var_Id   
 And t9.Result Is Not Null  
     Left Join dbo.tests t10 On t10.Result_On = e.TimeStamp   
 And t10.Var_Id = @Caliper_Range_Roll_A_Var_Id   
 And t10.Result Is Not Null  
     Left Join dbo.tests t11 On t11.Result_On = e.TimeStamp   
 And t11.Var_Id = @Caliper_Range_Roll_B_Var_Id   
 And t11.Result Is Not Null  
     Left Join dbo.tests t12 On t12.Result_On = e.TimeStamp   
 And t12.Var_Id = @Caliper_Range_Roll_C_Var_Id   
 And t12.Result Is Not Null  
     Left Join dbo.tests t13 On t13.Result_On = e.TimeStamp   
 And t13.Var_Id = @Caliper_Range_Roll_D_Var_Id   
 And t13.Result Is Not Null  
     Left Join dbo.tests t14 On t14.Result_On = e.TimeStamp   
 And t14.Var_Id = @Caliper_Range_Roll_E_Var_Id   
 And t14.Result Is Not Null  
     Left Join dbo.tests t15 On t15.Result_On = e.TimeStamp   
 And t15.Var_Id = @Caliper_Range_Roll_F_Var_Id   
 And t15.Result Is Not Null  
     Left Join dbo.tests t16 On t16.Result_On = e.TimeStamp   
 And t16.Var_Id = @Caliper_Range_Roll_G_Var_Id   
 And t16.Result Is Not Null  
     Left Join dbo.tests t17 On t17.Result_On = e.TimeStamp   
 And t17.Var_Id = @Caliper_Range_Roll_H_Var_Id   
 And t17.Result Is Not Null  
     Left Join dbo.tests t18 On t18.Result_On = e.TimeStamp   
 And t18.Var_Id = @CaliperManualProfileAvg_Var_ID   
 And t18.Result Is Not Null  
     Left Join dbo.tests t19 On t19.Result_On = e.TimeStamp   
 And t19.Var_Id = @CaliperManualProfileRange_Var_Id   
 And t19.Result Is Not Null  
     Left Join dbo.tests t20 On t20.Result_On = e.TimeStamp   
 And t20.Var_Id = @CaliperProfile_Var_Id   
 And t20.Result Is Not Null  
     Left Join dbo.tests t21 On t21.Result_On = e.TimeStamp   
 And t21.Var_Id = @Color_A_Value_Var_Id   
 And t21.Result Is Not Null  
     Left Join dbo.tests t22 On t22.Result_On = e.TimeStamp   
 And t22.Var_Id = @Color_B_Value_Var_Id   
 And t22.Result Is Not Null  
     Left Join dbo.tests t23 On t23.Result_On = e.TimeStamp   
 And t23.Var_Id = @Color_L_Value_Var_Id   
 And t23.Result Is Not Null  
     Left Join dbo.tests t24 On t24.Result_On = e.TimeStamp   
 And t24.Var_Id = @Holes_Large_Measurement_Var_Id   
 And t24.Result Is Not Null  
     Left Join dbo.tests t25 On t25.Result_On = e.TimeStamp   
 And t25.Var_Id = @Holes_Small_Count_Var_Id   
 And t25.Result Is Not Null  
     Left Join dbo.tests t26 On t26.Result_On = e.TimeStamp   
 And t26.Var_Id = @Sink_Average_Var_Id   
 And t26.Result Is Not Null       Left Join dbo.tests t27 On t27.Result_On = e.TimeStamp   
 And t27.Var_Id = @Softener_Tissue_DS_SD_AVG_Var_Id   
 And t27.Result Is Not Null  
     Left Join dbo.tests t28 On t28.Result_On = e.TimeStamp   
 And t28.Var_Id = @Softener_Tissue_DS_WR_AVG_Var_Id   
 And t28.Result Is Not Null  
     Left Join dbo.tests t29 On t29.Result_On = e.TimeStamp   
 And t29.Var_Id = @Softener_Tissue_TS_SD_AVG_Var_Id   
 And t29.Result Is Not Null  
     Left Join dbo.tests t30 On t30.Result_On = e.TimeStamp   
 And t30.Var_Id = @Softener_Tissue_TS_WR_AVG_Var_Id   
 And t30.Result Is Not Null  
     Left Join dbo.tests t31 On t31.Result_On = e.TimeStamp   
 And t31.Var_Id = @Specks_Gross_Count_Var_Id   
 And t31.Result Is Not Null  
     Left Join dbo.tests t32 On t32.Result_On = e.TimeStamp   
 And t32.Var_Id = @Specks_Large_Count_Var_Id   
 And t32.Result Is Not Null  
     Left Join dbo.tests t33 On t33.Result_On = e.TimeStamp   
 And t33.Var_Id = @Specks_Red_Count_Var_Id   
 And t33.Result Is Not Null  
     Left Join dbo.tests t34 On t34.Result_On = e.TimeStamp   
 And t34.Var_Id = @Specks_Small_Count_Var_Id   
 And t34.Result Is Not Null  
     Left Join dbo.tests t35 On t35.Result_On = e.TimeStamp   
 And t35.Var_Id = @Specks_Tiny_Count_Var_Id   
 And t35.Result Is Not Null  
     Left Join dbo.tests t36 On t36.Result_On = e.TimeStamp   
 And t36.Var_Id = @Stretch_CD_Var_Id   
 And t36.Result Is Not Null  
     Left Join dbo.tests t37 On t37.Result_On = e.TimeStamp   
 And t37.Var_Id = @Stretch_MD_Var_Id   
 And t37.Result Is Not Null  
     Left Join dbo.tests t38 On t38.Result_On = e.TimeStamp   
 And t38.Var_Id = @Tensile_CD_Var_Id   
 And t38.Result Is Not Null  
     Left Join dbo.tests t39 On t39.Result_On = e.TimeStamp   
 And t39.Var_Id = @Tensile_MD_Var_Id   
 And t39.Result Is Not Null  
     Left Join dbo.tests t40 On t40.Result_On = e.TimeStamp   
 And t40.Var_Id = @Tensile_Modulus_CD_Var_Id   
 And t40.Result Is Not Null  
     Left Join dbo.tests t41 On t41.Result_On = e.TimeStamp   
 And t41.Var_Id = @Tensile_Modulus_GM_Var_Id   
 And t41.Result Is Not Null  
     Left Join dbo.tests t42 On t42.Result_On = e.TimeStamp   
 And t42.Var_Id = @Tensile_Modulus_MD_Var_Id   
 And t42.Result Is Not Null  
     Left Join dbo.tests t43 On t43.Result_On = e.TimeStamp   
 And t43.Var_Id = @Tensile_Ratio_Var_Id   
 And t43.Result Is Not Null  
     Left Join dbo.tests t44 On t44.Result_On = e.TimeStamp   
 And t44.Var_Id = @Tensile_Total_Var_Id   
 And t44.Result Is Not Null  
     Left Join dbo.tests t45 On t45.Result_On = e.TimeStamp   
 And t45.Var_Id = @Web_Inspection_Var_Id   
 And t45.Result Is Not Null  
     Left Join dbo.tests t46 On t46.Result_On = e.TimeStamp   
 And t46.Var_Id = @Wet_Burst_Average_Var_Id   
 And t46.Result Is Not Null  
     Left Join dbo.tests t47 On t47.Result_On = e.TimeStamp   
 And t47.Var_Id = @Wet_Tensile_Average_Var_Id   
 And t47.Result Is Not Null  
     Left Join dbo.tests t48 On t48.Result_On = e.TimeStamp   
 And t48.Var_Id = @Wet_Tensile_CD_Var_Id   
 And t48.Result Is Not Null  
     Left Join dbo.tests t49 On t49.Result_On = e.TimeStamp   
 And t49.Var_Id = @Wet_Tensile_MD_Var_Id   
 And t49.Result Is Not Null  
     Left Join dbo.tests t50 On t50.Result_On = e.TimeStamp   
 And t50.Var_Id = @Wet_Tensile_Ratio_Var_Id   
 And t50.Result Is Not Null  
     Left Join dbo.tests t51 On t51.Result_On = e.TimeStamp   
 And t51.Var_Id = @Wet_Tensile_Total_Var_Id   
 And t51.Result Is Not Null  
     Left Join dbo.tests t52 On t52.Result_On = e.TimeStamp   
 And t52.Var_Id = @Wet_Dry_Tissue_Ratio_Var_Id   
 And t52.Result Is Not Null  
     Left Join dbo.tests t53 On t53.Result_On = e.TimeStamp   
 And t53.Var_Id = @Wet_Dry_Towel_Ratio_Var_Id   
 And t53.Result Is Not Null  
     Left Join dbo.tests t54 On t54.Result_On = e.TimeStamp   
 And t54.Var_Id = @Wet_Dry_Facial_Ratio_Var_Id   
 And t54.Result Is Not Null  
     Left Join dbo.tests t55 On t55.Result_On = e.TimeStamp   
 And t55.Var_Id = @Roll_Weight_Var_Id   
 And t55.Result Is Not Null  
     Left Join dbo.tests t56 On t56.Result_On = e.TimeStamp  --Namho Rev1.79  
 And t56.Var_Id = @Brightness_Var_Id   
 And t56.Result Is Not Null  
     Left Join dbo.tests t57 On t57.Result_On = e.TimeStamp  --Namho Rev1.80  
 And t57.Var_Id = @TopCaliperRollAAverage_Var_ID   
 And t57.Result Is Not Null  
     Left Join dbo.tests t58 On t58.Result_On = e.TimeStamp  --Namho Rev1.80  
 And t58.Var_Id = @TopCaliperRollBAverage_Var_ID   
 And t58.Result Is Not Null  
     Left Join dbo.tests t59 On t59.Result_On = e.TimeStamp  --Namho Rev1.80  
 And t59.Var_Id = @TopCaliperRollARange_Var_ID   
 And t59.Result Is Not Null  
     Left Join dbo.tests t60 On t60.Result_On = e.TimeStamp  --Namho Rev1.80  
 And t60.Var_Id = @TopCaliperRollBRange_Var_ID   
 And t60.Result Is Not Null  
  Left Join dbo.tests t61 On t61.Result_On = e.TimeStamp    
 And t61.Var_Id = @TopCaliperCurveFitRange_Var_ID   
 And t61.Result Is Not Null  
  Left Join dbo.tests t62 On t62.Result_On = e.TimeStamp    
 And t62.Var_Id = @TopCaliperCurveFitSkew_Var_ID   
 And t62.Result Is Not Null  
   Left Join dbo.tests t63 On t63.Result_On = e.TimeStamp    
 And t63.Var_Id = @LintWireSide_Var_Id   
 And t63.Result Is Not Null  
   Left Join dbo.tests t64 On t64.Result_On = e.TimeStamp    
 And t64.Var_Id = @LintFabricSide_Var_Id   
 And t64.Result Is Not Null  
  
  
Order By Prod_Desc,Timestamp  
--/* Rev1.73  
select @SQL =   
case  
when (select count(*) from dbo.#RawData) > 65000 then   
'select ' + char(39) + @TooMuchDataMsg + char(39) + ' [User Notification Msg]'  
when (select count(*) from dbo.#RawData) = 0 then   
'select ' + char(39) + @NoDataMsg + char(39) + ' [User Notification Msg]'  
else   
GBDB.dbo.fnLocal_RptTableTranslation('#RawData', @LanguageId)  
/*  Rev1.75  
else 'Select  convert(varchar,e.TimeStamp,110) [T/O Date],  
 convert(varchar,e.TimeStamp,108) [T/O Time],  
 e.Prod_Desc,  
 e.Team,  
 e.Shift,  
 e.TO_Number,  
 e.TID,  
 e.Roll_A_Status,  
 e.Roll_B_Status,  
 e.Roll_C_Status,  
 e.Roll_D_Status,  
 e.Roll_E_Status,  
 e.Roll_F_Status,  
 e.Roll_G_Status,  
 e.Roll_H_Status,  
 t1.Result As [Basis Weight Manual],  
 t2.Result As [Caliper Average Roll A],  
 t3.Result As [Caliper Average Roll B],  
 t4.Result As [Caliper Average Roll C],  
 t5.Result As [Caliper Average Roll D],  
 t6.Result As [Caliper Average Roll E],  
 t7.Result As [Caliper Average Roll F],  
 t8.Result As [Caliper Average Roll G],  
 t9.Result As [Caliper Average Roll H],  
 t10.Result As [Caliper Range Roll A],  
 t11.Result As [Caliper Range Roll B],  
 t12.Result As [Caliper Range Roll C],  
 t13.Result As [Caliper Range Roll D],  
 t14.Result As [Caliper Range Roll E],  
 t15.Result As [Caliper Range Roll F],  
 t16.Result As [Caliper Range Roll G],  
 t17.Result As [Caliper Range Roll H],  
 t18.Result AS [Caliper Manual Profile Avg],  
 t19.Result AS [Caliper Manual Profile Range],  
 t20.Result AS [Caliper Profile],  
 t21.Result As [Color A Value],  
 t22.Result As [Color B Value],  
 t23.Result As [Color L Value],  
 t24.Result As [Holes Large Measurement],  
 t25.Result As [Holes Small Count],  
 t26.Result As [Sink Average],  
 t27.Result As [Softener Tissue DS SD AVG],  
 t28.Result As [Softener Tissue DS WR AVG],  
 t29.Result As [Softener Tissue TS SD AVG],  
 t30.Result As [Softener Tissue TS WR AVG],  
 t31.Result As [Specks Gross Count],  
 t32.Result As [Specks Large Count],  
 t33.Result As [Specks Red Count],  
 t34.Result As [Specks Small Count],  
 t35.Result As [Specks Tiny Count],  
 t36.Result As [Stretch CD],  
 t37.Result As [Stretch MD],  
 t38.Result As [Tensile CD],  
 t39.Result As [Tensile MD],  
 t40.Result As [Tensile Modulus CD],  
 t41.Result As [Tensile Modulus GM],  
 t42.Result As [Tensile Modulus MD],  
 t43.Result As [Tensile Ratio],  
 t44.Result As [Tensile Total],  
 t45.Result As [Web Inspection],  
 t46.Result As [Wet Burst Average],  
 t47.Result As [Wet Tensile Average],  
 t48.Result As [Wet Tensile CD],  
 t49.Result As [Wet Tensile MD],  
 t50.Result As [Wet Tensile Ratio],  
 t51.Result As [Wet Tensile Total],  
 COALESCE(t52.Result, t53.Result,t54.Result) As [Wet Dry Ratio],  
 t55.Result As [Roll Weight]  
From @Turnovers e  
     Left Join dbo.tests t1 On t1.Result_On = e.TimeStamp   
 And t1.Var_Id = @Basis_Weight_Manual_Var_Id   
 And t1.Result Is Not Null  
     Left Join dbo.tests t2 On t2.Result_On = e.TimeStamp   
 And t2.Var_Id = @Caliper_Average_Roll_A_Var_Id   
 And t2.Result Is Not Null  
     Left Join dbo.tests t3 On t3.Result_On = e.TimeStamp   
 And t3.Var_Id = @Caliper_Average_Roll_B_Var_Id   
 And t3.Result Is Not Null  
     Left Join dbo.tests t4 On t4.Result_On = e.TimeStamp   
 And t4.Var_Id = @Caliper_Average_Roll_C_Var_Id   
 And t4.Result Is Not Null  
     Left Join dbo.tests t5 On t5.Result_On = e.TimeStamp   
 And t5.Var_Id = @Caliper_Average_Roll_D_Var_Id   
 And t5.Result Is Not Null  
     Left Join dbo.tests t6 On t6.Result_On = e.TimeStamp   
 And t6.Var_Id = @Caliper_Average_Roll_E_Var_Id   
 And t6.Result Is Not Null  
     Left Join dbo.tests t7 On t7.Result_On = e.TimeStamp   
 And t7.Var_Id = @Caliper_Average_Roll_F_Var_Id   
 And t7.Result Is Not Null  
     Left Join dbo.tests t8 On t8.Result_On = e.TimeStamp   
 And t8.Var_Id = @Caliper_Average_Roll_G_Var_Id   
 And t8.Result Is Not Null  
     Left Join dbo.tests t9 On t9.Result_On = e.TimeStamp   
 And t9.Var_Id = @Caliper_Average_Roll_H_Var_Id   
 And t9.Result Is Not Null  
     Left Join dbo.tests t10 On t10.Result_On = e.TimeStamp   
 And t10.Var_Id = @Caliper_Range_Roll_A_Var_Id   
 And t10.Result Is Not Null  
     Left Join dbo.tests t11 On t11.Result_On = e.TimeStamp   
 And t11.Var_Id = @Caliper_Range_Roll_B_Var_Id   
 And t11.Result Is Not Null  
     Left Join dbo.tests t12 On t12.Result_On = e.TimeStamp   
 And t12.Var_Id = @Caliper_Range_Roll_C_Var_Id   
 And t12.Result Is Not Null  
     Left Join dbo.tests t13 On t13.Result_On = e.TimeStamp   
 And t13.Var_Id = @Caliper_Range_Roll_D_Var_Id   
 And t13.Result Is Not Null  
     Left Join dbo.tests t14 On t14.Result_On = e.TimeStamp   
 And t14.Var_Id = @Caliper_Range_Roll_E_Var_Id   
 And t14.Result Is Not Null  
     Left Join dbo.tests t15 On t15.Result_On = e.TimeStamp   
 And t15.Var_Id = @Caliper_Range_Roll_F_Var_Id   
 And t15.Result Is Not Null  
     Left Join dbo.tests t16 On t16.Result_On = e.TimeStamp   
 And t16.Var_Id = @Caliper_Range_Roll_G_Var_Id   
 And t16.Result Is Not Null  
     Left Join dbo.tests t17 On t17.Result_On = e.TimeStamp   
 And t17.Var_Id = @Caliper_Range_Roll_H_Var_Id   
 And t17.Result Is Not Null  
     Left Join dbo.tests t18 On t18.Result_On = e.TimeStamp   
 And t18.Var_Id = @CaliperManualProfileAvg_Var_ID   
 And t18.Result Is Not Null  
     Left Join dbo.tests t19 On t19.Result_On = e.TimeStamp   
 And t19.Var_Id = @CaliperManualProfileRange_Var_Id   
 And t19.Result Is Not Null  
     Left Join dbo.tests t20 On t20.Result_On = e.TimeStamp   
 And t20.Var_Id = @CaliperProfile_Var_Id   
 And t20.Result Is Not Null  
     Left Join dbo.tests t21 On t21.Result_On = e.TimeStamp   
 And t21.Var_Id = @Color_A_Value_Var_Id   
 And t21.Result Is Not Null  
     Left Join dbo.tests t22 On t22.Result_On = e.TimeStamp   
 And t22.Var_Id = @Color_B_Value_Var_Id   
 And t22.Result Is Not Null  
     Left Join dbo.tests t23 On t23.Result_On = e.TimeStamp   
 And t23.Var_Id = @Color_L_Value_Var_Id   
 And t23.Result Is Not Null  
     Left Join dbo.tests t24 On t24.Result_On = e.TimeStamp   
 And t24.Var_Id = @Holes_Large_Measurement_Var_Id   
 And t24.Result Is Not Null  
     Left Join dbo.tests t25 On t25.Result_On = e.TimeStamp   
 And t25.Var_Id = @Holes_Small_Count_Var_Id   
 And t25.Result Is Not Null  
     Left Join dbo.tests t26 On t26.Result_On = e.TimeStamp   
 And t26.Var_Id = @Sink_Average_Var_Id   
 And t26.Result Is Not Null  
     Left Join dbo.tests t27 On t27.Result_On = e.TimeStamp   
 And t27.Var_Id = @Softener_Tissue_DS_SD_AVG_Var_Id   
 And t27.Result Is Not Null  
     Left Join dbo.tests t28 On t28.Result_On = e.TimeStamp   
 And t28.Var_Id = @Softener_Tissue_DS_WR_AVG_Var_Id   
 And t28.Result Is Not Null  
     Left Join dbo.tests t29 On t29.Result_On = e.TimeStamp   
 And t29.Var_Id = @Softener_Tissue_TS_SD_AVG_Var_Id   
 And t29.Result Is Not Null  
     Left Join dbo.tests t30 On t30.Result_On = e.TimeStamp   
 And t30.Var_Id = @Softener_Tissue_TS_WR_AVG_Var_Id   
 And t30.Result Is Not Null  
     Left Join dbo.tests t31 On t31.Result_On = e.TimeStamp   
 And t31.Var_Id = @Specks_Gross_Count_Var_Id   
 And t31.Result Is Not Null  
     Left Join dbo.tests t32 On t32.Result_On = e.TimeStamp   
 And t32.Var_Id = @Specks_Large_Count_Var_Id   
 And t32.Result Is Not Null  
     Left Join dbo.tests t33 On t33.Result_On = e.TimeStamp   
 And t33.Var_Id = @Specks_Red_Count_Var_Id   
 And t33.Result Is Not Null  
     Left Join dbo.tests t34 On t34.Result_On = e.TimeStamp   
 And t34.Var_Id = @Specks_Small_Count_Var_Id   
 And t34.Result Is Not Null  
     Left Join dbo.tests t35 On t35.Result_On = e.TimeStamp   
 And t35.Var_Id = @Specks_Tiny_Count_Var_Id   
 And t35.Result Is Not Null  
     Left Join dbo.tests t36 On t36.Result_On = e.TimeStamp   
 And t36.Var_Id = @Stretch_CD_Var_Id   
 And t36.Result Is Not Null  
     Left Join dbo.tests t37 On t37.Result_On = e.TimeStamp   
 And t37.Var_Id = @Stretch_MD_Var_Id   
 And t37.Result Is Not Null  
     Left Join dbo.tests t38 On t38.Result_On = e.TimeStamp   
 And t38.Var_Id = @Tensile_CD_Var_Id   
 And t38.Result Is Not Null  
     Left Join dbo.tests t39 On t39.Result_On = e.TimeStamp   
 And t39.Var_Id = @Tensile_MD_Var_Id   
 And t39.Result Is Not Null  
     Left Join dbo.tests t40 On t40.Result_On = e.TimeStamp   
 And t40.Var_Id = @Tensile_Modulus_CD_Var_Id   
 And t40.Result Is Not Null  
     Left Join dbo.tests t41 On t41.Result_On = e.TimeStamp   
 And t41.Var_Id = @Tensile_Modulus_GM_Var_Id   
 And t41.Result Is Not Null  
     Left Join dbo.tests t42 On t42.Result_On = e.TimeStamp   
 And t42.Var_Id = @Tensile_Modulus_MD_Var_Id   
 And t42.Result Is Not Null  
     Left Join dbo.tests t43 On t43.Result_On = e.TimeStamp   
 And t43.Var_Id = @Tensile_Ratio_Var_Id   
 And t43.Result Is Not Null  
     Left Join dbo.tests t44 On t44.Result_On = e.TimeStamp   
 And t44.Var_Id = @Tensile_Total_Var_Id   
 And t44.Result Is Not Null  
     Left Join dbo.tests t45 On t45.Result_On = e.TimeStamp   
 And t45.Var_Id = @Web_Inspection_Var_Id   
 And t45.Result Is Not Null  
     Left Join dbo.tests t46 On t46.Result_On = e.TimeStamp   
 And t46.Var_Id = @Wet_Burst_Average_Var_Id   
 And t46.Result Is Not Null  
     Left Join dbo.tests t47 On t47.Result_On = e.TimeStamp   
 And t47.Var_Id = @Wet_Tensile_Average_Var_Id   
 And t47.Result Is Not Null  
     Left Join dbo.tests t48 On t48.Result_On = e.TimeStamp   
 And t48.Var_Id = @Wet_Tensile_CD_Var_Id   
 And t48.Result Is Not Null  
     Left Join dbo.tests t49 On t49.Result_On = e.TimeStamp   
 And t49.Var_Id = @Wet_Tensile_MD_Var_Id   
 And t49.Result Is Not Null  
     Left Join dbo.tests t50 On t50.Result_On = e.TimeStamp   
 And t50.Var_Id = @Wet_Tensile_Ratio_Var_Id   
 And t50.Result Is Not Null  
     Left Join dbo.tests t51 On t51.Result_On = e.TimeStamp   
 And t51.Var_Id = @Wet_Tensile_Total_Var_Id   
 And t51.Result Is Not Null  
     Left Join dbo.tests t52 On t52.Result_On = e.TimeStamp   
 And t52.Var_Id = @Wet_Dry_Tissue_Ratio_Var_Id   
 And t52.Result Is Not Null  
     Left Join dbo.tests t53 On t53.Result_On = e.TimeStamp   
 And t53.Var_Id = @Wet_Dry_Towel_Ratio_Var_Id   
 And t53.Result Is Not Null  
     Left Join dbo.tests t54 On t54.Result_On = e.TimeStamp   
 And t54.Var_Id = @Wet_Dry_Facial_Ratio_Var_Id   
 And t54.Result Is Not Null  
     Left Join dbo.tests t55 On t55.Result_On = e.TimeStamp   
 And t55.Var_Id = @Roll_Weight_Var_Id   
 And t55.Result Is Not Null  
Order By Prod_Desc,Timestamp'  
*/  
end  
  
select @SQL = replace(@SQL, '''Basis Weight Manual''', coalesce((select '[' + var_desc  + ']' from dbo.variables where var_id = @Basis_Weight_Manual_Var_Id), '''Basis Weight Manual'''))  
select @SQL = replace(@SQL, '''Caliper Average Roll A''', coalesce((select '[' + var_desc + ']' from dbo.variables where var_id = @Caliper_Average_Roll_A_Var_Id), '''Caliper Average Roll A'''))  
select @SQL = replace(@SQL, '''Caliper Average Roll B''', coalesce((select '[' + var_desc + ']' from dbo.variables where var_id = @Caliper_Average_Roll_B_Var_Id), '''Caliper Average Roll B'''))  
select @SQL = replace(@SQL, '''Caliper Average Roll C''', coalesce((select '[' + var_desc + ']' from dbo.variables where var_id = @Caliper_Average_Roll_C_Var_Id), '''Caliper Average Roll C'''))  
select @SQL = replace(@SQL, '''Caliper Average Roll D''', coalesce((select '[' + var_desc + ']' from dbo.variables where var_id = @Caliper_Average_Roll_D_Var_Id), '''Caliper Average Roll D'''))  
select @SQL = replace(@SQL, '''Caliper Average Roll E''', coalesce((select '[' + var_desc + ']' from dbo.variables where var_id = @Caliper_Average_Roll_E_Var_Id), '''Caliper Average Roll E'''))  
select @SQL = replace(@SQL, '''Caliper Average Roll F''', coalesce((select '[' + var_desc + ']' from dbo.variables where var_id = @Caliper_Average_Roll_F_Var_Id), '''Caliper Average Roll F'''))  
select @SQL = replace(@SQL, '''Caliper Average Roll G''', coalesce((select '[' + var_desc + ']' from dbo.variables where var_id = @Caliper_Average_Roll_G_Var_Id), '''Caliper Average Roll G'''))  
select @SQL = replace(@SQL, '''Caliper Average Roll H''', coalesce((select '[' + var_desc + ']' from dbo.variables where var_id = @Caliper_Average_Roll_H_Var_Id), '''Caliper Average Roll H'''))  
select @SQL = replace(@SQL, '''Caliper Range Roll A''', coalesce((select '[' + var_desc + ']' from dbo.variables where var_id = @Caliper_Range_Roll_A_Var_Id), '''Caliper Range Roll A'''))  
select @SQL = replace(@SQL, '''Caliper Range Roll B''', coalesce((select '[' + var_desc + ']' from dbo.variables where var_id = @Caliper_Range_Roll_B_Var_Id), '''Caliper Range Roll B'''))  
select @SQL = replace(@SQL, '''Caliper Range Roll C''', coalesce((select '[' + var_desc + ']' from dbo.variables where var_id = @Caliper_Range_Roll_C_Var_Id), '''Caliper Range Roll C'''))  
select @SQL = replace(@SQL, '''Caliper Range Roll D''', coalesce((select '[' + var_desc + ']' from dbo.variables where var_id = @Caliper_Range_Roll_D_Var_Id), '''Caliper Range Roll D'''))  
select @SQL = replace(@SQL, '''Caliper Range Roll E''', coalesce((select '[' + var_desc + ']' from dbo.variables where var_id = @Caliper_Range_Roll_E_Var_Id), '''Caliper Range Roll E'''))  
select @SQL = replace(@SQL, '''Caliper Range Roll F''', coalesce((select '[' + var_desc + ']' from dbo.variables where var_id = @Caliper_Range_Roll_F_Var_Id), '''Caliper Range Roll F'''))  
select @SQL = replace(@SQL, '''Caliper Range Roll G''', coalesce((select '[' + var_desc + ']' from dbo.variables where var_id = @Caliper_Range_Roll_G_Var_Id), '''Caliper Range Roll G'''))  
select @SQL = replace(@SQL, '''Caliper Range Roll H''', coalesce((select '[' + var_desc + ']' from dbo.variables where var_id = @Caliper_Range_Roll_H_Var_Id), '''Caliper Range Roll H'''))  
select @SQL = replace(@SQL, '''Caliper Manual Profile Avg''', coalesce((select '[' + var_desc + ']' from dbo.variables where var_id = @CaliperManualProfileAvg_Var_ID ), '''Top Caliper Manual Profile Avg'''))  
select @SQL = replace(@SQL, '''Caliper Manual Profile Range''', coalesce((select '[' + var_desc + ']' from dbo.variables where var_id = @CaliperManualProfileRange_Var_Id ), '''Top Caliper Manual Profile Range'''))  
select @SQL = replace(@SQL, '''Caliper Profile''', coalesce((select '[' + var_desc + ']' from dbo.variables where var_id = @CaliperProfile_Var_Id), '''Top Caliper Profile'''))  
select @SQL = replace(@SQL, '''Color A Value''', coalesce((select '[' + var_desc + ']' from dbo.variables where var_id = @Color_A_Value_Var_Id), '''Color A Value'''))  
select @SQL = replace(@SQL, '''Color B Value''', coalesce((select '[' + var_desc + ']' from dbo.variables where var_id = @Color_B_Value_Var_Id), '''Color B Value'''))  
select @SQL = replace(@SQL, '''Color L Value''', coalesce((select '[' + var_desc + ']' from dbo.variables where var_id = @Color_L_Value_Var_Id), '''Color L Value'''))  
select @SQL = replace(@SQL, '''Holes Large Measurement''', coalesce((select '[' + var_desc + ']' from dbo.variables where var_id = @Holes_Large_Measurement_Var_Id), '''Holes Large Measurement'''))  
select @SQL = replace(@SQL, '''Holes Small Count''', coalesce((select '[' + var_desc + ']' from dbo.variables where var_id = @Holes_Small_Count_Var_Id), '''Holes Small Count'''))  
select @SQL = replace(@SQL, '''Sink Average''', coalesce((select '[' + var_desc + ']' from dbo.variables where var_id = @Sink_Average_Var_Id), '''Sink Average'''))  
select @SQL = replace(@SQL, '''Softener Tissue DS SD AVG''', coalesce((select '[' + var_desc + ']' from dbo.variables where var_id = @Softener_Tissue_DS_SD_AVG_Var_Id), '''Softener Tissue DS SD AVG'''))  
select @SQL = replace(@SQL, '''Softener Tissue DS WR AVG''', coalesce((select '[' + var_desc + ']' from dbo.variables where var_id = @Softener_Tissue_DS_WR_AVG_Var_Id), '''Softener Tissue DS WR AVG'''))  
select @SQL = replace(@SQL, '''Softener Tissue TS SD AVG''', coalesce((select '[' + var_desc + ']' from dbo.variables where var_id = @Softener_Tissue_TS_SD_AVG_Var_Id), '''Softener Tissue TS SD AVG'''))  
select @SQL = replace(@SQL, '''Softener Tissue TS WR AVG''', coalesce((select '[' + var_desc + ']' from dbo.variables where var_id = @Softener_Tissue_TS_WR_AVG_Var_Id), '''Softener Tissue TS WR AVG'''))  
select @SQL = replace(@SQL, '''Specks Gross Count''', coalesce((select '[' + var_desc + ']' from dbo.variables where var_id = @Specks_Gross_Count_Var_Id), '''Specks Gross Count'''))  
select @SQL = replace(@SQL, '''Specks Large Count''', coalesce((select '[' + var_desc + ']' from dbo.variables where var_id = @Specks_Large_Count_Var_Id), '''Specks Large Count'''))  
select @SQL = replace(@SQL, '''Specks Red Count''', coalesce((select '[' + var_desc + ']' from dbo.variables where var_id = @Specks_Red_Count_Var_Id), '''Specks Red Count'''))  
select @SQL = replace(@SQL, '''Specks Small Count''', coalesce((select '[' + var_desc + ']' from dbo.variables where var_id = @Specks_Small_Count_Var_Id), '''Specks Small Count'''))  
select @SQL = replace(@SQL, '''Specks Tiny Count''', coalesce((select '[' + var_desc + ']' from dbo.variables where var_id = @Specks_Tiny_Count_Var_Id), '''Specks Tiny Count'''))  
select @SQL = replace(@SQL, '''Stretch CD''', coalesce((select '[' + var_desc + ']' from dbo.variables where var_id = @Stretch_CD_Var_Id), '''Stretch CD'''))  
select @SQL = replace(@SQL, '''Stretch MD''', coalesce((select '[' + var_desc + ']' from dbo.variables where var_id = @Stretch_MD_Var_Id), '''Stretch MD'''))  
select @SQL = replace(@SQL, '''Tensile CD''', coalesce((select '[' + var_desc + ']' from dbo.variables where var_id = @Tensile_CD_Var_Id), '''Tensile CD'''))  
select @SQL = replace(@SQL, '''Tensile MD''', coalesce((select '[' + var_desc + ']' from dbo.variables where var_id = @Tensile_MD_Var_Id), '''Tensile MD'''))  
select @SQL = replace(@SQL, '''Tensile Modulus CD''', coalesce((select '[' + var_desc + ']' from dbo.variables where var_id = @Tensile_Modulus_CD_Var_Id), '''Tensile Modulus CD'''))  
select @SQL = replace(@SQL, '''Tensile Modulus GM''', coalesce((select '[' + var_desc + ']' from dbo.variables where var_id = @Tensile_Modulus_GM_Var_Id), '''Tensile Modulus GM'''))  
select @SQL = replace(@SQL, '''Tensile Modulus MD''', coalesce((select '[' + var_desc + ']' from dbo.variables where var_id = @Tensile_Modulus_MD_Var_Id), '''Tensile Modulus MD'''))  
select @SQL = replace(@SQL, '''Tensile Ratio''', coalesce((select '[' + var_desc + ']' from dbo.variables where var_id = @Tensile_Ratio_Var_Id), '''Tensile Ratio'''))  
select @SQL = replace(@SQL, '''Tensile Total''', coalesce((select '[' + var_desc + ']' from dbo.variables where var_id = @Tensile_Total_Var_Id), '''Tensile Total'''))  
select @SQL = replace(@SQL, '''Web Inspection''', coalesce((select '[' + var_desc + ']' from dbo.variables where var_id = @Web_Inspection_Var_Id), '''Web Inspection'''))  
select @SQL = replace(@SQL, '''Wet Burst Average''', coalesce((select '[' + var_desc + ']' from dbo.variables where var_id = @Wet_Burst_Average_Var_Id), '''Wet Burst Average'''))  
select @SQL = replace(@SQL, '''Wet Tensile Average''', coalesce((select '[' + var_desc + ']' from dbo.variables where var_id = @Wet_Tensile_Average_Var_Id), '''Wet Tensile Average'''))  
select @SQL = replace(@SQL, '''Wet Tensile CD''', coalesce((select '[' + var_desc + ']' from dbo.variables where var_id = @Wet_Tensile_CD_Var_Id), '''Wet Tensile CD'''))  
select @SQL = replace(@SQL, '''Wet Tensile MD''', coalesce((select '[' + var_desc + ']' from dbo.variables where var_id = @Wet_Tensile_MD_Var_Id), '''Wet Tensile MD'''))  
select @SQL = replace(@SQL, '''Wet Tensile Ratio''', coalesce((select '[' + var_desc + ']' from dbo.variables where var_id = @Wet_Tensile_Ratio_Var_Id), '''Wet Tensile Ratio'''))  
select @SQL = replace(@SQL, '''Wet Tensile Total''', coalesce((select '[' + var_desc + ']' from dbo.variables where var_id = @Wet_Tensile_Total_Var_Id), '''Wet Tensile Total'''))  
select @SQL = replace(@SQL, '''Roll Weight''', coalesce((select '[' + var_desc + ']' from dbo.variables where var_id = @Roll_Weight_Var_Id), '''Roll Weight'''))  
select @SQL = replace(@SQL, '''Brightness''', coalesce((select '[' + var_desc + ']' from dbo.variables where var_id = @Brightness_Var_Id), '''Brightness''')) -- Namho Rev1.79  
select @SQL = replace(@SQL, '''Top Caliper Roll A Average''', coalesce((select '[' + var_desc + ']' from dbo.variables where var_id = @TopCaliperRollAAverage_Var_Id), '''Top Caliper Roll A Average''')) --Namho Rev1.80  
select @SQL = replace(@SQL, '''Top Caliper Roll B Average''', coalesce((select '[' + var_desc + ']' from dbo.variables where var_id = @TopCaliperRollBAverage_Var_Id), '''Top Caliper Roll B Average''')) --Namho Rev1.80  
select @SQL = replace(@SQL, '''Top Caliper Roll A Range''', coalesce((select '[' + var_desc + ']' from dbo.variables where var_id = @TopCaliperRollARange_Var_Id), '''Top Caliper Roll A Range'''))  --Namho Rev1.80  
select @SQL = replace(@SQL, '''Top Caliper Roll B Range''', coalesce((select '[' + var_desc + ']' from dbo.variables where var_id = @TopCaliperRollBRange_Var_Id), '''Top Caliper Roll B Range'''))  --Namho Rev1.80  
select @SQL = replace(@SQL, '''Top Caliper Curve Fit Range''', coalesce((select '[' + var_desc + ']' from dbo.variables where var_id = @TopCaliperCurveFitRange_Var_Id), '''Top Caliper Curve Fit Range'''))    
select @SQL = replace(@SQL, '''Top Caliper Curve Fit Skew''', coalesce((select '[' + var_desc + ']' from dbo.variables where var_id = @TopCaliperCurveFitSkew_Var_Id), '''Top Caliper Curve Fit Skew'''))    
select @SQL = replace(@SQL, '''Lint Wire Side''', coalesce((select '[' + var_desc + ']' from dbo.variables where var_id = @LintWireSide_Var_Id), '''Lint Wire Side'''))   
select @SQL = replace(@SQL, '''Lint Fabric side''', coalesce((select '[' + var_desc + ']' from dbo.variables where var_id = @LintFabricSide_Var_Id), '''Lint Fabric Side'''))   
  
if charindex(@TooMuchDataMsg,@SQL)=0 and charindex(@NoDataMsg,@SQL)=0  -- Rev1.76  
 select @SQL = @SQL + ' order by [Product_Desc], [T/O Date], [T/O Time]'  -- Rev1.75  
  
Exec (@SQL)   
--*/  --Rev1.73  
  
-- Limits result set  
  
SELECT p.Prod_Desc,  
 --GBDB.dbo.fnLocal_GlblParseInfoWithSpaces(v.Extended_Info, 'GlblDesc='), --Rev1.74  
 v.var_desc,  --Rev1.74  
 vs.L_Reject,  
 vs.Target,  
 vs.U_Reject  
FROM dbo.Var_Specs vs  
 INNER JOIN dbo.Variables v ON vs.Var_Id = v.Var_Id  
 INNER JOIN dbo.Products p ON vs.Prod_Id = p.Prod_Id  
WHERE vs.Effective_Date < @Report_Start_Time  
 AND ( vs.Expiration_Date > @Report_Start_Time  
  OR vs.Expiration_Date IS NULL)  
 AND vs.Var_Id IN ( @Basis_Weight_Manual_Var_Id,  
    @Caliper_Average_Roll_A_Var_Id,  
    @Caliper_Average_Roll_B_Var_Id,  
    @Caliper_Average_Roll_C_Var_Id,  
    @Caliper_Average_Roll_D_Var_Id,  
    @Caliper_Average_Roll_E_Var_Id,  
    @Caliper_Average_Roll_F_Var_Id,  
    @Caliper_Average_Roll_G_Var_Id,  
    @Caliper_Average_Roll_H_Var_Id,  
    @Caliper_Range_Roll_A_Var_Id,  
    @Caliper_Range_Roll_B_Var_Id,  
    @Caliper_Range_Roll_C_Var_Id,  
    @Caliper_Range_Roll_D_Var_Id,  
    @Caliper_Range_Roll_E_Var_Id,  
    @Caliper_Range_Roll_F_Var_Id,  
    @Caliper_Range_Roll_G_Var_Id,  
    @Caliper_Range_Roll_H_Var_Id,  
    @CaliperManualProfileAvg_Var_ID,  
    @CaliperManualProfileRange_Var_ID,  
--    @TopCaliperManualProfileAvg_Var_ID,  
--    @TopCaliperManualProfileRange_Var_ID,  
    @CaliperProfile_Var_ID,  
    @Color_A_Value_Var_Id,  
    @Color_B_Value_Var_Id,  
    @Color_L_Value_Var_Id,  
    @Holes_Large_Measurement_Var_Id,  
    @Holes_Small_Count_Var_Id,  
    @Sink_Average_Var_Id,  
    @Softener_Tissue_DS_SD_AVG_Var_Id,  
    @Softener_Tissue_DS_WR_AVG_Var_Id,  
    @Softener_Tissue_TS_SD_AVG_Var_Id,  
    @Softener_Tissue_TS_WR_AVG_Var_Id,  
    @Specks_Gross_Count_Var_Id,  
    @Specks_Large_Count_Var_Id,  
    @Specks_Red_Count_Var_Id,  
    @Specks_Small_Count_Var_Id,  
    @Specks_Tiny_Count_Var_Id,  
    @Stretch_CD_Var_Id,  
    @Stretch_MD_Var_Id,  
    @Tensile_CD_Var_Id,  
    @Tensile_MD_Var_Id,  
    @Tensile_Modulus_CD_Var_Id,  
    @Tensile_Modulus_GM_Var_Id,  
    @Tensile_Modulus_MD_Var_Id,  
    @Tensile_Ratio_Var_Id,  
    @Tensile_Total_Var_Id,  
    @Web_Inspection_Var_Id,  
    @Wet_Burst_Average_Var_Id,  
    @Wet_Tensile_Average_Var_Id,  
    @Wet_Tensile_CD_Var_Id,  
    @Wet_Tensile_MD_Var_Id,  
    @Wet_Tensile_Ratio_Var_Id,  
    @Wet_Tensile_Total_Var_Id,  
    @Wet_Dry_Tissue_Ratio_Var_Id,  
    @Wet_Dry_Towel_Ratio_Var_Id,  
    @Wet_Dry_Facial_Ratio_Var_Id,  
    @Brightness_Var_Id, -- Namho Rev1.79  
    @TopCaliperRollAAverage_Var_Id,  
    @TopCaliperRollBAverage_Var_Id,  
    @TopCaliperRollARange_Var_Id,  
    @TopCaliperRollBRange_Var_Id,  
    @TopCaliperCurveFitRange_Var_Id,  
    @TopCaliperCurveFitSkew_Var_Id,  
    @LintWireSide_Var_ID,  
    @LintFabricSide_Var_ID  
    )  
ORDER BY p.Prod_Desc, Var_Desc  
  
  
END  
  
drop table dbo.#RawData  
  
  

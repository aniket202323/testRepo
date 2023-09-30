  /*  
Stored Procedure: spLocal_RptPmkgSBsDetail.sql  
Author:   Jeff Jaeger, Stier Automation  
Date Created:  05/27/04  
  
Description:  
=========  
Revision 2.2 Vince King 2005-Jun-09  
  
This procedure integrates code from spLocal_GetSBbyProductSummaryData and spLocal_GetSBDetailDataRev2.  
  
INPUTS: Start Time  
 End Time  
 Line Name (without TT prefix)  
 Data Category  (not used now)  
 Report Product Id:   -1 Returns Product Names, plus all individual Sheet Breaks grouped by Reasons, Count, Times, Tonnes  
           0 or Null - Returns Sheet Breaks grouped by Reason. Not by Product.  
          -2 Returns Product Names, Breaks Count, Downtime, Tonnes  grouped by Product  
          Product ID - Returns Product Name, plus all individual Sheet Breaks grouped by Reasons, Count, Times, Tonnes  
  
CALLED BY:  RptPmkgSBsDetail.xlt (Excel/VBA Template)  
  
CALLS: None  
  
Revision Change Date Who  What  
======== =========== ====  =====  
2.0  2004-05-27 JSJ  - Integrated code from spLocal_GetSBbyProductSummaryData and   
        spLocal_GetSBDetailDataRev2.  
      - Changed all variables with a data type of real to data type float.  
      - Added @ErrorMessages table, #DetailData1, #DetailData2, #DetailData3,  
        #Summary_Data_Limited, and related code for each.  
      - Converted the temporary tables to table variables where appropriate.  
      - Removed some unused code that was in the original code.  
      - Added parameter validation checks.  
      - Added the @UserName parameter.  
      - Addeed code to get the Language_ID and to translate table hearder   
        names.  
      - Updated the code to use the global description to pull variable IDs,   
        instead of using the var_desc.  
      - Removed the parameter @Data_Category, since it was not being used.  
      - Added flow-control around the result sets.  
      - Note that while this stored procedure can return a variety of result   
        sets for details, based on the prod id passed in, the template is hard   
        coded to only pass in a -1.  We need to decide if we are going to allow   
        this flexibility to be used or not.         
      - Added an addition to the where clause in the summary cursor definition,   
        "and lower(p.prod_desc) <> 'no grade'"  
  
2.1  2005-06-08 VMK  - Modified Result Set select statements to have multiple joins  
            to the Timed_Event_Catagories table for each reason category.  
          - Also found where the summary Repulper Tons were not matching   
            up with the detail.  The summary was using cast to convert and  
            format, detail was using convert.  I changed all of the details  
            to be the same as the summary.  
  
2.2  2005-06-09 VMK  - Count was not matching between the summary and detail sections,  
            I missed it in testing.  The detail section was counting ALL  
            events whether they were sheetbreaks or not.  Modified SELECT  
            statements to sum Result for the @Sheetbreak_Count_Var_Id.  
  
=====================================================  
*/  
CREATE PROCEDURE dbo.spLocal_RptPmkgSBsDetail  
--Declare  
  @Report_Start_Time datetime,  
  @Report_End_Time  datetime,  
  @Line_Name     varchar(50),  
  @Report_Prod_Id  int,  
  @UserName    varchar(30)  
  
AS  
  
/* MP  
  
Select  --@PL_Id    = 2,  
 @Line_Name  = 'MP3M',  
 @Report_Start_Time  = '2002-04-01 00:00:00',  
 @Report_End_Time    = '2002-05-01 00:00:00',  
  @Report_Prod_Id  = -1,   -- 0 --  -2   -1  --Null 1013 --  
 @UserName  = 'ComXClient'   
  
*/  
  
/* AZ  
  
Select  --@PL_Id    = 2,  
 @Line_Name  = 'AZM1',  
 @Report_Start_Time  = '2002-04-01 00:00:00',  
 @Report_End_Time    = '2002-04-04 00:00:00',  
  @Report_Prod_Id  = -1,   -- 0 --  -2   -1  --Null 1013 --  
 @UserName  = 'ComXClient'   
  
*/  
  
-- WITZ  
-- Select  --@PL_Id    = 2,  
--  @Line_Name  = 'WIPM',  
--  @Report_Start_Time  = '2005-06-05 06:00:00',  
--  @Report_End_Time    = '2005-06-06 06:00:00',  
--   @Report_Prod_Id  = -1,   -- 0 --  -2   -1  --Null 1013 --  
--  @UserName  = 'ComXClient'   
  
  
/************************************************************************************************  
*                                 Global execution switches                                     *  
************************************************************************************************/  
SET NOCOUNT ON  
SET ANSI_WARNINGS OFF  
  
  
/************************************************************************************************  
* Create temporary tables         *  
************************************************************************************************/  
  
DECLARE @ErrorMessages TABLE (  
 ErrMsg      varchar(255)   
)  
   
  
Declare @Production_Runs Table (  
 Start_Id      int Primary Key,  
 Prod_Id      int Not Null,  
 Prod_Desc     varchar(50),  
 Start_Time     datetime Not Null,  
 End_Time      datetime Not Null  
)  
  
Declare @Summary_Data table(  
 Product      varchar(50),  
 Repulper_Tons    decimal(10,2),  
 SheetBreak_Time   decimal(10,2),  
 Sheetbreak_Count   int  
)  
  
  
create table #Summary_Data_Limited(  
 Product      varchar(50),  
 Repulper_Tons    decimal(10,2),  
 SheetBreak_Time   decimal(10,2),  
 Sheetbreak_Count   int  
)  
  
  
Create Table #DetailData1(  
 Product      varchar(50),  
 Category      varchar(100),  
 Cause       varchar(100),  
 Failure_Mode    varchar(100),  
 Failure_Mode_Count   int,  
 Uptime      float,  
 Downtime      float,  
 Repulper_Tons    decimal(10,2),  
 Stops       float,  
 UPLTRx      float,  
 Minor_Stop     float,  
 Breakdown     float,  
 Process_Failure   float,  
 Blocked_Starved   int  
)  
  
  
create table #DetailData2(  
 Category      varchar(100),  
 Cause       varchar(100),  
 Failure_Mode    varchar(100),  
 Failure_Mode_Count  int,   
 Downtime      float,  
 Uptime      float,  
 Repulper_Tons    decimal(10,2),  
 Primary_Stops    float,  
 Extended_Stops    float,  
 Primary_Tons    float,  
 Extended_Tons    float,  
 Primary_Time    float,  
 Extended_Time    float,  
 UPLTRx      float,  
 Minor_Stop     float,  
 Breakdown     float,  
 Process_Failure   float,  
 Blocked_Starved   int  
)  
  
  
create table #DetailData3(  
 Product      varchar(50),  
 Failure_Mode_Count  int,   
 Downtime      float,  
 Repulper_Tons    decimal(10,2)  
)  
  
  
-----------------------------------------------------------  
-- Validate input parameters  
-----------------------------------------------------------  
  
IF IsDate(@Report_Start_Time) <> 1  
BEGIN  
 INSERT @ErrorMessages (ErrMsg)  
  VALUES ('@Report_Start_Time is not a Date.')  
 GOTO ReturnResultSets  
END  
  
IF IsDate(@Report_End_Time) <> 1  
BEGIN  
 INSERT @ErrorMessages (ErrMsg)  
  VALUES ('@Report_Start_Time is not a Date.')  
 GOTO ReturnResultSets  
END  
  
IF (select count(*) from prod_lines where pl_desc = 'TT ' + @Line_Name) = 0  
BEGIN  
 INSERT @ErrorMessages (ErrMsg)  
  VALUES ('@Line_Name does not exist.')  
 GOTO ReturnResultSets  
END  
  
IF (select 'invalid' where @Report_Prod_Id not in (-1,-2,0)   
  and @Report_Prod_id is not null) = 'invalid'   
BEGIN  
 INSERT @ErrorMessages (ErrMsg)  
  VALUES ('@Report_Prod_Id is not valid.')  
 GOTO ReturnResultSets  
END  
  
IF (SELECT count(*) FROM Users WHERE UserName = @UserName) = 0  
BEGIN  
 INSERT @ErrorMessages (ErrMsg)  
  VALUES ('@UserName is not valid.')  
 GOTO ReturnResultSets  
END  
  
  
------------------------------------------------------------  
-- Declare program variables  
------------------------------------------------------------  
  
Declare @PL_Id      int,  
 @Result        varchar(25),  
 @Total        decimal(10,2),  
 @Count        int,  
 @Production_PU_Id     int,  
 @Quality_PU_Id      int,  
 @Rolls_PU_Id      int,  
 @Sheetbreak_PU_Id     int,  
 @Downtime_PU_Id     int,  
 @Invalid_Status_Id    int,  
 @Repulper_Tons_Var_Id   int,  
 @Repulper_Tons_Sum    decimal(10,2),  
 @Sheetbreak_Count_Var_Id  int,  
 @Sheetbreak_Count     int,  
 @Product_Start_Time    datetime,  
 @Product_End_Time     datetime,  
 @Prod_Id        int,  
 @Prod_Desc       varchar(50),  
 @Last_Prod_Id      int,  
 @Last_Prod_Desc     varchar(50),  
 @Downtime1       float,  
 @Downtime2       float,  
 @Downtime3       float,  
 @Sheetbreak_Time     decimal(10,2),  
 @Mechanical_Desc     varchar(50),  
 @Electrical_Desc     varchar(50),  
 @Process_Failure_Desc   varchar(50),  
 @Blocked_Starved_Desc   varchar(50),  
 @Mechanical_Id      int,  
 @Electrical_Id      int,  
 @Process_Failure_Id    int,  
 @Blocked_Starved_Id    int,  
 @Uptime_Var_Id      int,  
 @Invalid_Status_Desc    varchar(50),  
 @LanguageId       integer,  
 @UserId        integer,  
 @LanguageParmId     integer,  
 @NoDataMsg        varchar(50),  
 @TooMuchDataMsg      varchar(50),  
 @SQL          varchar(8000)  
  
   
  
/************************************************************************************************  
*                                     Initialization                                                               *  
************************************************************************************************/  
Select @Invalid_Status_Desc = 'Invalid',  
 @Mechanical_Desc = 'Category:Mechanical Equipment',  
 @Electrical_Desc = 'Category:Electrical Equipment',  
 @Process_Failure_Desc = 'Category:Process/Operational',  
 @Blocked_Starved_Desc = 'Category:Blocked/Starved',  
 @Repulper_Tons_Sum    = Null,  
 @Sheetbreak_Time   = Null,  
 @Sheetbreak_Count    = Null  
  
  
select   @LanguageParmID  = 8,  
@LanguageId  = NULL  
  
SELECT @UserId = User_Id  
FROM Users  
WHERE UserName = @UserName  
  
SELECT @LanguageId = CASE   
   WHEN isnumeric(ltrim(rtrim(Value))) = 1 THEN convert(float, ltrim(rtrim(Value)))  
   ELSE NULL  
   END  
FROM User_Parameters  
WHERE [User_Id] = @UserId  
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
 end  
  
  
IF @LanguageId IS NULL  
 SELECT @LanguageId = 0  
  
  
select @NoDataMsg = GBDB.dbo.fnLocal_GlblTranslation('NO DATA meets the given criteria', @LanguageId)  
select @TooMuchDataMsg = GBDB.dbo.fnLocal_GlblTranslation('There are more results than can be displayed', @LanguageId)  
  
  
/************************************************************************************************  
*                                     Get Configuration                                                               *  
************************************************************************************************/  
  
/* Get the line id */  
  
Select @PL_Id = PL_Id  
From Prod_Lines  
Where PL_Desc = 'TT ' + ltrim(rtrim(@Line_Name))  
  
/* Get Different PU Ids */  
  
Select @Production_PU_Id = PU_Id  
From Prod_Units  
Where PL_Id = @PL_Id And PU_Desc = @Line_Name + ' Production'  
  
Select @Sheetbreak_PU_Id = PU_Id  
From Prod_Units  
Where PL_Id = @PL_Id And PU_Desc = @Line_Name + ' Sheetbreak'  
  
/* Get variables */  
  
SELECT @Sheetbreak_Count_Var_Id = GBDB.dbo.fnLocal_GlblGetVarId(@Sheetbreak_PU_Id, 'Sheetbreak Primary')  
SELECT @Uptime_Var_Id = GBDB.dbo.fnLocal_GlblGetVarId(@Sheetbreak_PU_Id, 'Sheet Reel Time')  
SELECT @Repulper_Tons_Var_Id = GBDB.dbo.fnLocal_GlblGetVarId(@Sheetbreak_PU_Id, 'Tons Repulper')  
  
Select @Mechanical_Id = ERC_Id  
From Event_Reason_Catagories  
Where ERC_Desc = @Mechanical_Desc  
  
Select @Electrical_Id = ERC_Id  
From Event_Reason_Catagories  
Where ERC_Desc = @Electrical_Desc  
  
Select @Process_Failure_Id = ERC_Id  
From Event_Reason_Catagories  
Where ERC_Desc = @Process_Failure_Desc  
  
Select @Blocked_Starved_Id = ERC_Id  
From Event_Reason_Catagories  
Where ERC_Desc = @Blocked_Starved_Desc  
  
Select @Invalid_Status_Id = TEStatus_Id  
From Timed_Event_Status  
Where PU_Id = @Sheetbreak_PU_Id And TEStatus_Name = @Invalid_Status_Desc  
  
/************************************************************************************************  
* Get Summary Production Statistics                                 *  
************************************************************************************************/  
  
/* Open cursor for product runs */  
  
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
                ps.Start_Time < @Report_End_Time And (ps.End_Time > @Report_Start_Time Or ps.End_Time Is Null) and  
  lower(p.prod_desc) <> 'no grade'  
     Order By p.Prod_Desc Asc, Start_Time Asc  
     For Read Only  
  
Open ProductRuns  
  
   
     Fetch First From ProductRuns Into @Prod_Id, @Prod_Desc, @Product_Start_Time, @Product_End_Time  
     Select  @Last_Prod_Id   = @Prod_Id,  
  @Last_Prod_Desc = @Prod_Desc  
  
     While @@FETCH_STATUS = 0  
          Begin  
  
          /* Repulper Tons */  
          Select @Total = sum(cast(Result As decimal(10,2))),  
  @Count = count(Result)  
          From tests   
          Where Var_Id = @Repulper_Tons_Var_Id and Result_On >= @Product_Start_Time And Result_On < @Product_End_Time And Result Is Not Null  
  
          If @Count > 0  
               Select @Repulper_Tons_Sum  = isnull(@Repulper_Tons_Sum, 0) + @Total  
  
   /************************************************************************************************  
          *                                         Sheetbreak Time/Count                                 *  
          ************************************************************************************************/  
          -- Reinitialize  
          Select  @Downtime1 = 0.0,  
  @Downtime2 = 0.0,  
  @Downtime3 = 0.0  
  
          -- Get Invalid sheetbreak status  
          Select @Invalid_Status_Id = TEStatus_Id  
          From Timed_Event_Status  
          Where PU_Id = @Sheetbreak_PU_Id And TEStatus_Name = 'Invalid'  
  
          -- Get data for all records that fall entirely between the times   
          Select @Downtime1 = convert(float, Sum(Datediff(s, Start_Time, End_Time)))  
          From Timed_Event_Details  
          Where PU_Id = @Sheetbreak_PU_Id And (TEStatus_Id <> @Invalid_Status_Id Or TEStatus_Id Is Null) And  
                Start_Time > @Product_Start_Time And Start_Time < @Product_End_Time And End_Time > @Product_Start_Time And End_Time < @Product_End_Time And End_Time Is Not Null  
  
          -- Get data for any records that cross the starting time or span the entire time.   
          Select @Downtime2 = convert(float, Datediff(s, @Product_Start_Time, End_Time))  
          From Timed_Event_Details  
          Where PU_Id = @Sheetbreak_PU_Id And (TEStatus_Id <> @Invalid_Status_Id Or TEStatus_Id Is Null) And  
               Start_Time <= @Product_Start_Time And (End_Time > @Product_Start_Time Or End_Time Is Null)  
  
          -- Get data for any records that cross the ending time   
          Select @Downtime3 = convert(float, Datediff(s, Start_Time, @Product_End_Time))  
          From Timed_Event_Details  
          Where PU_Id = @Sheetbreak_PU_Id And (TEStatus_Id <> @Invalid_Status_Id Or TEStatus_Id Is Null) And  
               Start_Time > @Product_Start_Time And Start_Time < @Product_End_Time And (End_Time >= @Product_End_Time Or End_Time Is Null)  
  
          Select @Sheetbreak_Time = IsNull(@Sheetbreak_Time, 0) + (IsNull(@Downtime1, 0.0) + IsNull(@Downtime2, 0.0) + IsNull(@Downtime3, 0.0))/60  
  
          -- Can optionally replace with Proficy Turnover Weight and add Repulper tons to it.  
          Select @Sheetbreak_Count = isnull(@Sheetbreak_Count, 0) + floor(sum(cast(Result As Float)))  
          From tests   
          Where Var_Id = @Sheetbreak_Count_Var_Id and Result_On >= @Product_Start_Time And Result_On < @Product_End_Time And Result Is Not Null  
  
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
               Insert Into @Summary_Data ( Product,  
               Repulper_Tons,  
               SheetBreak_Time,  
               Sheetbreak_Count)  
                Values (  @Last_Prod_Desc,  
          @Repulper_Tons_Sum,  
          @Sheetbreak_Time,  
          @Sheetbreak_Count)  
  
               If @@FETCH_STATUS = 0  
                    Begin  
                    /* Reinitialize */  
                    Select    
        @Repulper_Tons_Sum   = Null,  
        @Sheetbreak_Time   = Null,  
        @Sheetbreak_Count   = Null,  
        @Last_Prod_Id     = @Prod_Id,  
        @Last_Prod_Desc   = @Prod_Desc  
                    End  
               End  
          End  
  
Close ProductRuns  
Deallocate ProductRuns   
  
insert into #Summary_Data_Limited  
Select TOP 10 *  
From @Summary_Data  
  
/************************************************************************************************  
* Get Production Statistics for Sheetbreak Details                                                   *  
************************************************************************************************/  
  
If @Report_Prod_Id = -1  
     Insert into #DetailData1  
     Select  p.Prod_Desc       As Product,  
  r1.Event_Reason_Name       As Category,  
  r2.Event_Reason_Name       As Cause,  
  r3.Event_Reason_Name       As Failure_Mode,  
  sum(convert(integer, sbt.Result))    As Failure_Mode_Count,     -- 2005-JUN-09 VMK Rev2.2 Added  
--   count(ted.TEDet_Id)        As Failure_Mode_Count,     -- 2005-JUN-09 VMK Rev2.2 Removed  
  sum(convert(float, ut.Result))      As Uptime,  
  sum(convert(float, datediff(s, ted.Start_Time, ted.End_Time))/60) As Downtime,  
  sum(cast(rt.Result As decimal(10,2)))  As Repulper_Tons,    -- 2005-06-08 VMK Rev2.1  
  sum(Case When convert(float, ut.Result) > 0 Then 1   
    Else 0   
    End)         As Stops,  
  sum(Case When convert(float, ut.Result) > 2*convert(float, datediff(s, ted.Start_Time, ted.End_Time))/60 And convert(float, ut.Result) > 0 Then 1  
    Else 0  
    End)        As UPLTRx,  
  sum(Case When convert(float, datediff(s, ted.Start_Time, ted.End_Time))/60 < 2 Then 1  
    Else 0  
    End)        As Minor_Stop,  
  sum(Case When (tedcb.ERC_Id = @Mechanical_Id Or tedcb.ERC_Id = @Electrical_Id) And  
         convert(float, datediff(s, ted.Start_Time, ted.End_Time))/60 > 2 Then 1  
    Else 0  
    End)        As Breakdown,  
  sum(Case When tedcpf.ERC_Id = @Process_Failure_Id And  
         convert(float, datediff(s, ted.Start_Time, ted.End_Time))/60 > 2 Then 1  
    Else 0  
    End)        As Process_Failure,  
  sum(Case When tedcbs.ERC_Id = @Blocked_Starved_Id Then 1  
    Else 0  
    End)        As Blocked_Starved  
     From Timed_Event_Details ted  
          Inner Join Production_Starts ps On ps.PU_Id = @Sheetbreak_PU_Id And ted.Start_Time >= ps.Start_Time   
  And ted.End_Time < Case When ps.End_Time is Null Then @Report_End_Time Else ps.End_Time End  
          Inner Join Products p On ps.Prod_Id = p.Prod_Id  
          Left Join Local_Timed_Event_Categories tedcb On ted.TEDet_Id = tedcb.TEDet_Id and    -- 2005-JUN-08 VMK Rev2.1  
                     (tedcb.erc_id = @Mechanical_Id or tedcb.erc_id = @Electrical_Id)  
          Left Join Local_Timed_Event_Categories tedcpf On ted.TEDet_Id = tedcpf.TEDet_Id and  
                     (tedcpf.erc_id = @Process_Failure_Id)  
          Left Join Local_Timed_Event_Categories tedcbs On ted.TEDet_Id = tedcbs.TEDet_Id and  
                     (tedcbs.erc_id = @Blocked_Starved_Id)  
          Left Join Event_Reasons r1 On ted.Reason_Level1 = r1.Event_Reason_Id  
          Left Join Event_Reasons r2 On ted.Reason_Level2 = r2.Event_Reason_Id  
          Left Join Event_Reasons r3 On ted.Reason_Level3 = r3.Event_Reason_Id  
          Left Join tests ut On ut.Var_Id = @Uptime_Var_Id And ut.Result_On = ted.Start_Time  
          Left Join tests rt On rt.Var_Id = @Repulper_Tons_Var_Id And rt.Result_On = ted.Start_Time  
    Left Join tests sbt On sbt.Var_Id = @Sheetbreak_Count_Var_Id And sbt.Result_On = ted.Start_Time -- 2005-JUN-09 VMK Rev2.2  
     Where ted.PU_Id = @Sheetbreak_PU_Id   
 And (ted.TEStatus_Id <> @Invalid_Status_Id   
  Or ted.TEStatus_Id Is Null)   
 And     ( (ted.Start_Time <= @Report_Start_Time   
   And ted.End_Time >=  @Report_Start_Time And ted.End_Time < @Report_End_Time)   
  Or ( (ted.Start_Time >= @Report_Start_Time And ted.Start_Time < @Report_End_Time)   
   And (ted.End_Time > @Report_End_Time   
    Or ted.End_Time Is Null))   
  Or (ted.Start_Time <= @Report_Start_Time   
   And (ted.End_Time >= @Report_End_Time  
    Or ted.End_Time Is Null))   
  Or ( (ted.Start_Time >= @Report_Start_Time And ted.Start_Time < @Report_End_Time)   
   And (ted.End_Time <= @Report_End_Time)))   
     Group By p.Prod_Desc, r1.Event_Reason_Name, r2.Event_Reason_Name, r3.Event_Reason_Name  
     Order By p.Prod_Desc , Repulper_Tons Desc  
     --Order By p.Prod_Desc, Downtime Desc  
  
Else If @Report_Prod_Id = 0 OR @Report_Prod_Id IS NULL  
     Insert into #DetailData2  
     Select  r1.Event_Reason_Name       As Category,  
  r2.Event_Reason_Name       As Cause,  
  r3.Event_Reason_Name       As Failure_Mode,  
  sum(convert(integer, sbt.Result))    As Failure_Mode_Count,     -- 2005-JUN-09 VMK Rev2.2 Added  
--   count(ted.TEDet_Id)        As Failure_Mode_Count,     -- 2005-JUN-09 VMK Rev2.2 Removed  
  sum(convert(float, datediff(s, ted.Start_Time, ted.End_Time))/60) As Downtime,  
  sum(convert(float, ut.Result))      As Uptime,  
  sum(cast(rt.Result As decimal(10,2)))  As Repulper_Tons,    -- 2005-06-08 VMK Rev2.1  
  sum(Case When convert(float, ut.Result) > 0 Then 1   
    Else 0   
    End)         As Primary_Stops,  
  sum(Case When convert(float, ut.Result) = 0 Then 1   
    Else 0   
    End)         As Extended_Stops,  
  sum(Case When convert(float, ut.Result) > 0 Then rt.Result   
    Else cast(0.0 as float)   
    End)         As Primary_Tons,  
  sum(Case When convert(float, ut.Result) = 0 Then rt.Result   
    Else cast(0.0 as float)   
    End)         As Extended_Tons,  
  sum(Case When convert(float, ut.Result) > 0 Then convert(float,datediff(s, ted.Start_Time, ted.End_Time))/60  
    Else cast(0.0 as float)   
    End)         As Primary_Time,  
  sum(Case When convert(float, ut.Result) = 0 Then convert(float,datediff(s, ted.Start_Time, ted.End_Time))/60  
    Else cast(0.0 as float)   
    End)         As Extended_Time,  
  sum(Case When convert(float, ut.Result) > 2*convert(float, datediff(s, ted.Start_Time, ted.End_Time))/60 And convert(float, ut.Result) > 0 Then 1  
    Else 0  
    End)        As UPLTRx,  
  sum(Case When convert(float, datediff(s, ted.Start_Time, ted.End_Time))/60 < 2 Then 1  
    Else 0  
    End)        As Minor_Stop,  
  sum(Case When (tedcb.ERC_Id = @Mechanical_Id Or tedcb.ERC_Id = @Electrical_Id) And  
         convert(float, datediff(s, ted.Start_Time, ted.End_Time))/60 > 2 Then 1  
    Else 0  
    End)        As Breakdown,  
  sum(Case When tedcpf.ERC_Id = @Process_Failure_Id And  
         convert(float, datediff(s, ted.Start_Time, ted.End_Time))/60 > 2 Then 1  
    Else 0  
    End)        As Process_Failure,  
  sum(Case When tedcbs.ERC_Id = @Blocked_Starved_Id Then 1  
    Else 0  
    End)        As Blocked_Starved  
     From Timed_Event_Details ted  
          Left Join Local_Timed_Event_Categories tedcb On ted.TEDet_Id = tedcb.TEDet_Id and    -- 2005-JUN-08 VMK Rev2.1  
                     (tedcb.erc_id = @Mechanical_Id or tedcb.erc_id = @Electrical_Id)  
          Left Join Local_Timed_Event_Categories tedcpf On ted.TEDet_Id = tedcpf.TEDet_Id and  
                     (tedcpf.erc_id = @Process_Failure_Id)  
          Left Join Local_Timed_Event_Categories tedcbs On ted.TEDet_Id = tedcbs.TEDet_Id and  
                     (tedcbs.erc_id = @Blocked_Starved_Id)  
          Left Join Event_Reasons r1 On ted.Reason_Level1 = r1.Event_Reason_Id  
          Left Join Event_Reasons r2 On ted.Reason_Level2 = r2.Event_Reason_Id  
          Left Join Event_Reasons r3 On ted.Reason_Level3 = r3.Event_Reason_Id  
          Left Join tests ut On ut.Var_Id = @Uptime_Var_Id And ut.Result_On = ted.Start_Time-- And isnumeric(result) = 1 -- Uptime  
          Left Join tests rt On rt.Var_Id = @Repulper_Tons_Var_Id And rt.Result_On = ted.Start_Time-- And isnumeric(result) = 1 -- Uptime  
    Left Join tests sbt On sbt.Var_Id = @Sheetbreak_Count_Var_Id And sbt.Result_On = ted.Start_Time -- 2005-JUN-09 VMK Rev2.2  
     Where ted.PU_Id = @Sheetbreak_PU_Id   
 And (ted.TEStatus_Id <> @Invalid_Status_Id   
  Or ted.TEStatus_Id Is Null)   
 And     ( (ted.Start_Time <= @Report_Start_Time   
   And ted.End_Time >=  @Report_Start_Time And ted.End_Time < @Report_End_Time)   
  Or ( (ted.Start_Time >= @Report_Start_Time And ted.Start_Time < @Report_End_Time)   
   And (ted.End_Time > @Report_End_Time   
    Or ted.End_Time Is Null))   
  Or (ted.Start_Time <= @Report_Start_Time   
   And (ted.End_Time >= @Report_End_Time  
    Or ted.End_Time Is Null))   
  Or ( (ted.Start_Time >= @Report_Start_Time And ted.Start_Time < @Report_End_Time)   
   And (ted.End_Time <= @Report_End_Time)))   
     Group By r1.Event_Reason_Name, r2.Event_Reason_Name, r3.Event_Reason_Name  --, Type  
     Order By Repulper_Tons Desc  
     --Order By Downtime Desc  
-------  
Else If @Report_Prod_Id = -2  
     Insert into #DetailData3  
     Select  p.Prod_Desc        As Product,  
  sum(convert(integer, sbt.Result))    As Failure_Mode_Count,     -- 2005-JUN-09 VMK Rev2.2 Added  
--   count(ted.TEDet_Id)        As Failure_Mode_Count,     -- 2005-JUN-09 VMK Rev2.2 Removed  
  sum(convert(float, datediff(s, ted.Start_Time, ted.End_Time))/60) As Downtime,  
  sum(cast(rt.Result As decimal(10,2)))  As Repulper_Tons    -- 2005-06-08 VMK Rev2.1  
     From Timed_Event_Details ted  
          Inner Join Production_Starts ps On ps.PU_Id = @Sheetbreak_PU_Id And ted.Start_Time >= ps.Start_Time   
  --And ted.End_Time < ps.End_Time  
  And ted.End_Time < Case When ps.End_Time is Null Then @Report_End_Time Else ps.End_Time End  
          Inner Join Products p On ps.Prod_Id = p.Prod_Id  
--        Left Join Local_Timed_Event_Categories tedc On ted.TEDet_Id = tedc.TEDet_Id  
          Left Join tests ut On ut.Var_Id = @Uptime_Var_Id And ut.Result_On = ted.Start_Time-- And isnumeric(result) = 1 -- Uptime  
          Left Join tests rt On rt.Var_Id = @Repulper_Tons_Var_Id And rt.Result_On = ted.Start_Time-- And isnumeric(result) = 1 -- Uptime  
    Left Join tests sbt On sbt.Var_Id = @Sheetbreak_Count_Var_Id And sbt.Result_On = ted.Start_Time -- 2005-JUN-09 VMK Rev2.2  
     Where ted.PU_Id = @Sheetbreak_PU_Id   
 And (ted.TEStatus_Id <> @Invalid_Status_Id   
  Or ted.TEStatus_Id Is Null)   
 And ps.Prod_Id = @Report_Prod_Id   
 And     ( (ted.Start_Time <= @Report_Start_Time   
   And ted.End_Time >=  @Report_Start_Time And ted.End_Time < @Report_End_Time)   
  Or ( (ted.Start_Time >= @Report_Start_Time And ted.Start_Time < @Report_End_Time)   
   And (ted.End_Time > @Report_End_Time   
    Or ted.End_Time Is Null))   
  Or (ted.Start_Time <= @Report_Start_Time   
   And (ted.End_Time >= @Report_End_Time  
    Or ted.End_Time Is Null))   
  Or ( (ted.Start_Time >= @Report_Start_Time And ted.Start_Time < @Report_End_Time)   
   And (ted.End_Time <= @Report_End_Time)))   
     Group By p.Prod_Desc  
  
-------  
Else  
     Insert into #DetailData1  
     Select  p.Prod_Desc        As Product,  
  r1.Event_Reason_Name       As Category,  
  r2.Event_Reason_Name       As Cause,  
  r3.Event_Reason_Name       As Failure_Mode,  
  sum(convert(integer, sbt.Result))    As Failure_Mode_Count,     -- 2005-JUN-09 VMK Rev2.2 Added  
--   count(ted.TEDet_Id)        As Failure_Mode_Count,     -- 2005-JUN-09 VMK Rev2.2 Removed  
  sum(convert(float, ut.Result))      As Uptime,  
  sum(convert(float, datediff(s, ted.Start_Time, ted.End_Time))/60) As Downtime,  
  sum(cast(rt.Result As decimal(10,2)))  As Repulper_Tons,    -- 2005-06-08 VMK Rev2.1  
  sum(Case When convert(float, ut.Result) > 0 Then 1   
    Else 0   
    End)         As Stops,  
  sum(Case When convert(float, ut.Result) > 2*convert(float, datediff(s, ted.Start_Time, ted.End_Time))/60 And convert(float, ut.Result) > 0 Then 1  
    Else 0  
    End)        As UPLTRx,  
  sum(Case When convert(float, datediff(s, ted.Start_Time, ted.End_Time))/60 < 2 Then 1  
    Else 0  
    End)        As Minor_Stop,  
  sum(Case When (tedcb.ERC_Id = @Mechanical_Id Or tedcb.ERC_Id = @Electrical_Id) And  
         convert(float, datediff(s, ted.Start_Time, ted.End_Time))/60 > 2 Then 1  
    Else 0  
    End)        As Breakdown,  
  sum(Case When tedcpf.ERC_Id = @Process_Failure_Id And  
         convert(float, datediff(s, ted.Start_Time, ted.End_Time))/60 > 2 Then 1  
    Else 0  
    End)        As Process_Failure,  
  sum(Case When tedcbs.ERC_Id = @Blocked_Starved_Id Then 1  
    Else 0  
    End)        As Blocked_Starved  
     From Timed_Event_Details ted  
          Inner Join Production_Starts ps On ps.PU_Id = @Sheetbreak_PU_Id And ted.Start_Time >= ps.Start_Time   
  --And ted.End_Time < ps.End_Time  
  And ted.End_Time < Case When ps.End_Time is Null Then @Report_End_Time Else ps.End_Time End  
          Inner Join Products p On ps.Prod_Id = p.Prod_Id  
          Left Join Local_Timed_Event_Categories tedcb On ted.TEDet_Id = tedcb.TEDet_Id and    -- 2005-JUN-08 VMK Rev2.1  
                     (tedcb.erc_id = @Mechanical_Id or tedcb.erc_id = @Electrical_Id)  
          Left Join Local_Timed_Event_Categories tedcpf On ted.TEDet_Id = tedcpf.TEDet_Id and  
                     (tedcpf.erc_id = @Process_Failure_Id)  
          Left Join Local_Timed_Event_Categories tedcbs On ted.TEDet_Id = tedcbs.TEDet_Id and  
                     (tedcbs.erc_id = @Blocked_Starved_Id)  
          Left Join Event_Reasons r1 On ted.Reason_Level1 = r1.Event_Reason_Id  
          Left Join Event_Reasons r2 On ted.Reason_Level2 = r2.Event_Reason_Id  
          Left Join Event_Reasons r3 On ted.Reason_Level3 = r3.Event_Reason_Id  
          Left Join tests ut On ut.Var_Id = @Uptime_Var_Id And ut.Result_On = ted.Start_Time-- And isnumeric(result) = 1 -- Uptime  
          Left Join tests rt On rt.Var_Id = @Repulper_Tons_Var_Id And rt.Result_On = ted.Start_Time-- And isnumeric(result) = 1 -- Uptime  
    Left Join tests sbt On sbt.Var_Id = @Sheetbreak_Count_Var_Id And sbt.Result_On = ted.Start_Time -- 2005-JUN-09 VMK Rev2.2  
     Where ted.PU_Id = @Sheetbreak_PU_Id   
 And (ted.TEStatus_Id <> @Invalid_Status_Id   
  Or ted.TEStatus_Id Is Null)   
 And ps.Prod_Id = @Report_Prod_Id   
 And     ( (ted.Start_Time <= @Report_Start_Time   
   And ted.End_Time >=  @Report_Start_Time And ted.End_Time < @Report_End_Time)   
  Or ( (ted.Start_Time >= @Report_Start_Time And ted.Start_Time < @Report_End_Time)   
   And (ted.End_Time > @Report_End_Time   
    Or ted.End_Time Is Null))   
  Or (ted.Start_Time <= @Report_Start_Time   
   And (ted.End_Time >= @Report_End_Time  
    Or ted.End_Time Is Null))   
  Or ( (ted.Start_Time >= @Report_Start_Time And ted.Start_Time < @Report_End_Time)   
   And (ted.End_Time <= @Report_End_Time)))  
     Group By p.Prod_Desc, r1.Event_Reason_Name, r2.Event_Reason_Name, r3.Event_Reason_Name  
     Order By Repulper_Tons Desc  -- , p.Prod_Desc    
  
---------------------------------------------------------------------------------------  
--  Return data results  
---------------------------------------------------------------------------------------  
  
ReturnResultSets:  
  
  
 if (select count(*) from @ErrorMessages) > 0  
  
 begin  
  
  SELECT ErrMsg  
  FROM @ErrorMessages  
  
 end  
   
 else  
  
 begin  
  
  
 ----------------------------------------  
 -- Return ErrorMessages result set.  
 ----------------------------------------  
  
 -- errors  index 1  
  
 SELECT ErrMsg  
 FROM @ErrorMessages  
  
  
 select @SQL =   
 case  
 when (select count(*) from #Summary_Data_Limited) > 65000 then   
 'select ' + char(39) + @TooMuchDataMsg + char(39) + ' [User Notification Msg]'  
 when (select count(*) from #Summary_Data_Limited) = 0 then   
 'select ' + char(39) + @NoDataMsg + char(39) + ' [User Notification Msg]'  
 else GBDB.dbo.fnLocal_RptTableTranslation('#Summary_Data_Limited', @LanguageId)  
 end  
 Exec (@SQL)   
  
  
 if (select count(*) from #DetailData1) > 0   
  
  begin  
  
   select @SQL =   
   case  
   when (select count(*) from #DetailData1) > 65000 then   
   'select ' + char(39) + @TooMuchDataMsg + char(39) + ' [User Notification Msg]'  
   when (select count(*) from #DetailData1) = 0 then   
   'select ' + char(39) + @NoDataMsg + char(39) + ' [User Notification Msg]'  
   else GBDB.dbo.fnLocal_RptTableTranslation('#DetailData1', @LanguageId)  
   end  
   Exec (@SQL)   
  
  end  
  
 if (select count(*) from #DetailData2) > 0   
  
  begin  
  
   select @SQL =   
   case  
   when (select count(*) from #DetailData2) > 65000 then   
   'select ' + char(39) + @TooMuchDataMsg + char(39) + ' [User Notification Msg]'  
   when (select count(*) from #DetailData2) = 0 then   
   'select ' + char(39) + @NoDataMsg + char(39) + ' [User Notification Msg]'  
   else GBDB.dbo.fnLocal_RptTableTranslation('#DetailData2', @LanguageId)  
   end  
   Exec (@SQL)   
  
  end  
  
 if (select count(*) from #DetailData3) > 0   
  
  begin  
  
   select @SQL =   
   case  
   when (select count(*) from #DetailData3) > 65000 then   
   'select ' + char(39) + @TooMuchDataMsg + char(39) + ' [User Notification Msg]'  
   when (select count(*) from #DetailData3) = 0 then   
   'select ' + char(39) + @NoDataMsg + char(39) + ' [User Notification Msg]'  
   else GBDB.dbo.fnLocal_RptTableTranslation('#DetailData3', @LanguageId)  
   end  
   Exec (@SQL)   
  
  end  
  
 end  
  
---------------------------------------------------------------------------  
--  Drop the temporary tables  
---------------------------------------------------------------------------  
  
Drop Table #Summary_Data_Limited  
drop table #DetailData1  
drop table #DetailData2  
drop table #DetailData3  
  
  
  

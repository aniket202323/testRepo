  /*  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Altered by  : Eric Perron, System technologies for industry  
Date   : 2005-11-02  
Version  : 1.0.1  
Purpose  : Redesign of SP (Compliant with Proficy 3 and 4).  
     Added [dbo] template when referencing objects.  
     Replace temp table for table variable   
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Stored Procedure: spLocal_GetSBbyProductSummaryData  
Author:   C. Emerson (MSI)  
Date Created:  04/25/02  
  
Description:  
=========  
This procedure summarizes Sheet Break data for a defined period.  From a given start time, end time, production line,   
 it will summarize the sheetbreaks by Product run.  
  
INPUTS: Start Time  
 End Time  
 Production Line Name (without 'TT' prefix)  
  
CALLED BY:  SheetBreaksDetail (Excel/VBA Template)  
  
CALLS: None  
  
Revision Change Date Who What  
======== =========== ==== =====  
0.0  4/25/02  CE Original Creation  
  
*/  
CREATE PROCEDURE dbo.spLocal_GetSBbyProductSummaryData  
  
  
--Declare  
  
@Report_Start_Time datetime,  
@Report_End_Time datetime,  
@Line_Name   varchar(50)  
  
AS  
  
Declare @Time1 datetime, @Time2 datetime, @Time3 datetime, @Time4 datetime, @Time5 datetime  
  
  
/************************************************************************************************  
*                                                                                               *  
*                                 Global execution switches                                     *  
*                                                                                               *  
************************************************************************************************/  
SET NOCOUNT ON  
SET ANSI_WARNINGS OFF  
  
  
/************************************************************************************************  
*                                                                                               *  
*                                        Declarations                                           *  
*                                                                                               *  
************************************************************************************************/  
-- NOT USE  
-- DECLARE @Production_Runs TABLE (  
--  Start_Id int Primary Key,  
--  Prod_Id  int Not Null,  
--  Prod_Desc varchar(50),  
--  Start_Time datetime Not Null,  
--  End_Time datetime Not Null  
-- )  
  
DECLARE @Summary_Data TABLE (  
 Product    varchar(50),  
 Repulper_Tons   decimal(10,2),  
 SheetBreak_Time   decimal(10,2),  
 Sheetbreak_Count  int  
)  
  
Declare @PL_Id     int,  
 @Result     varchar(25),  
 @Total     decimal(10,2),  
 @Count     int,  
 @Production_PU_Id   int,  
 @Quality_PU_Id    int,  
 @Rolls_PU_Id    int,  
 @Sheetbreak_PU_Id   int,  
 @Downtime_PU_Id    int,  
 @Invalid_Status_Id   int,  
 @Repulper_Tons_Var_Id   int,  
 @Repulper_Tons_Sum   decimal(10,2),  
 @Sheetbreak_Count_Var_Id  int,  
 @Sheetbreak_Count   int,  
 @Product_Start_Time   datetime,  
 @Product_End_Time   datetime,  
 @Prod_Id    int,  
 @Prod_Desc    varchar(50),  
 @Last_Prod_Id    int,  
 @Last_Prod_Desc    varchar(50),  
 @Downtime1    float,  
 @Downtime2    float,  
 @Downtime3    float,  
 @Sheetbreak_Time   decimal(10,2)  
  
/* Testing...   
  
Select  --@PL_Id    = 2,  
 @Line_Name  = 'GP06',  
 @Report_Start_Time  = '2002-03-01 00:00:00',  
 @Report_End_Time    = '2002-03-31 00:00:00'  
  --@Data_Category  = 'Production' --'SheetBreaks' --'Quality' --   
  
--exec spLocal_GetSBbyProductSummaryData '2002-04-30 00:00:00','2002-05-01 00:00:00','GP06'  
*/  
-- END OF TEST DATA ---  
  
/************************************************************************************************  
*                                                 *  
*                                     Initialization                                                               *  
*                                                                                                                               *  
************************************************************************************************/  
Select  @Repulper_Tons_Sum    = Null,  
 @Sheetbreak_Time   = Null,  
 @Sheetbreak_Count    = Null  
  
/************************************************************************************************  
*                                                                                                                               *  
*                                     Get Configuration                                                               *  
*                                                                                                                               *  
************************************************************************************************/  
/* Get the line id */  
Select @PL_Id = PL_Id  
From [dbo].Prod_Lines  
Where PL_Desc = 'TT ' + ltrim(rtrim(@Line_Name))  
  
/* Get Different PU Ids */  
Select @Production_PU_Id = PU_Id  
From [dbo].Prod_Units  
Where PL_Id = @PL_Id And PU_Desc = @Line_Name + ' Production'  
  
Select @Sheetbreak_PU_Id = PU_Id  
From [dbo].Prod_Units  
Where PL_Id = @PL_Id And PU_Desc = @Line_Name + ' Sheetbreak'  
  
Select @Repulper_Tons_Var_Id = Var_Id  
From [dbo].Variables  
Where Var_Desc = 'Tons Repulper' And PU_Id = @Sheetbreak_PU_Id  
  
Select @Sheetbreak_Count_Var_Id = Var_Id  
From [dbo].Variables  
Where Var_Desc = 'Sheetbreak Primary' And PU_Id = @Sheetbreak_PU_Id  
  
/************************************************************************************************  
*                                                                                               *  
*                                     Get Production Statistics                                 *  
*                                                                                               *  
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
     From [dbo].Production_Starts ps  
          Inner Join [dbo].Products p On ps.Prod_Id = p.Prod_Id  
     Where PU_Id = @Production_PU_Id And  
                ps.Start_Time < @Report_End_Time And (ps.End_Time > @Report_Start_Time Or ps.End_Time Is Null)  
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
          From [dbo].tests   
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
          From [dbo].Timed_Event_Status  
          Where PU_Id = @Sheetbreak_PU_Id And TEStatus_Name = 'Invalid'  
  
          -- Get data for all records that fall entirely between the times   
          Select @Downtime1 = convert(float, Sum(Datediff(s, Start_Time, End_Time)))  
          From [dbo].Timed_Event_Details  
          Where PU_Id = @Sheetbreak_PU_Id And (TEStatus_Id <> @Invalid_Status_Id Or TEStatus_Id Is Null) And  
                Start_Time > @Product_Start_Time And Start_Time < @Product_End_Time And End_Time > @Product_Start_Time And End_Time < @Product_End_Time And End_Time Is Not Null  
  
          -- Get data for any records that cross the starting time or span the entire time.   
          Select @Downtime2 = convert(float, Datediff(s, @Product_Start_Time, End_Time))  
          From [dbo].Timed_Event_Details  
          Where PU_Id = @Sheetbreak_PU_Id And (TEStatus_Id <> @Invalid_Status_Id Or TEStatus_Id Is Null) And  
               Start_Time <= @Product_Start_Time And (End_Time > @Product_Start_Time Or End_Time Is Null)  
  
          -- Get data for any records that cross the ending time   
          Select @Downtime3 = convert(float, Datediff(s, Start_Time, @Product_End_Time))  
          From [dbo].Timed_Event_Details  
          Where PU_Id = @Sheetbreak_PU_Id And (TEStatus_Id <> @Invalid_Status_Id Or TEStatus_Id Is Null) And  
               Start_Time > @Product_Start_Time And Start_Time < @Product_End_Time And (End_Time >= @Product_End_Time Or End_Time Is Null)  
  
          Select @Sheetbreak_Time = IsNull(@Sheetbreak_Time, 0) + (IsNull(@Downtime1, 0.0) + IsNull(@Downtime2, 0.0) + IsNull(@Downtime3, 0.0))/60  
  
          -- Can optionally replace with Proficy Turnover Weight and add Repulper tons to it.  
          Select @Sheetbreak_Count = isnull(@Sheetbreak_Count, 0) + floor(sum(cast(Result As Float)))  
          From [dbo].tests   
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
        @Repulper_Tons_Sum    = Null,  
        @Sheetbreak_Time   = Null,  
        @Sheetbreak_Count   = Null,  
        @Last_Prod_Id     = @Prod_Id,  
        @Last_Prod_Desc    = @Prod_Desc  
                    End  
               End  
          End  
  
     -- Return data  
     Select TOP 10 Product,Repulper_Tons,SheetBreak_Time,Sheetbreak_Count  
     From @Summary_Data  
  
  
-- Drop Table #Production_Runs  
-- Drop Table #Summary_Data  
Close ProductRuns  
Deallocate ProductRuns   
  
--select * from #Production_Runs  
SET NOCOUNT OFF  
  

/*
Get Waste data for a set of production units.
@UnitList                - Comma separated list of production units
@StartTime               - Start time
@EndTime                 - End time
@RSTypeList              - list of resultsets that should be returned
                            1 - Top N Waste by Unit
                            2 - Top N Waste by Location (Source Unit)
                            3 - Top N Waste by Fault
                            4 - Top N Waste by Reason (Level 1)
                            5 - Top N Waste by Shift
                            6 - Top N Waste by Crew
                            7 - Top N Waste by Operator
                            8 - Top N Waste by Product
                            9 - Unassigned Waste by unit/operator
                           10 - Top N Waste by Category
@N                       - Number of items to return for Top N result sets
@InTimeZone              - Ex: 'India Standard Time','Central Stardard Time'
*/
CREATE Procedure [dbo].[spBF_WasteGetReportData]
@UnitList                nvarchar(max),
@StartTime               datetime = NULL,
@EndTime                 datetime = NULL,
@RSTypeList              nVarChar(500),
@N                       int,
@InTimeZone              nVarChar(200) = NULL
AS
set nocount on
-------------------------------------------------------------------------------------------------
-- Unit List
-------------------------------------------------------------------------------------------------
If (@UnitList is Not Null)
 	 Set @UnitList = REPLACE(@UnitList, ' ', '')
if ((@UnitList is Not Null) and (LEN(@UnitList) = 0))
 	 Set @UnitList = Null
Declare @Units Table (UnitId int)
if (@UnitList is not null)
 	 begin
 	  	 insert into @Units (UnitId)
 	  	 select Id from [dbo].[fnCmn_IdListToTable]('Prod_Units',@UnitList,',')
 	 end
Set @UnitList = ''
SELECT @UnitList = @UnitList + COALESCE(convert(nVarChar(50), UnitId) + ',' ,'')
  FROM @Units
  order by UnitId
if (LEN(@UnitList) > 0)
 	 Set @UnitList = Left(@UnitList, LEN(@UnitList) - 1)
-------------------------------------------------------------------------------------------------
-- Prepare list of Result Set Types requested
-------------------------------------------------------------------------------------------------
If (@RSTypeList is Not Null)
 	 Set @RSTypeList = REPLACE(@RSTypeList, ' ', '')
if ((@RSTypeList is Not Null) and (LEN(@RSTypeList) = 0))
 	 Set @RSTypeList = Null
if (@RSTypeList is null)
 	 return
Declare @RSTypes Table (TypeId int)
insert into @RSTypes (TypeId)
select Id from [dbo].[fnCmn_IdListToTable]('RSTypes',@RSTypeList,',')
-------------------------------------------------------------------------------------------------
-- Get Data Into Temporary Table
-------------------------------------------------------------------------------------------------
DECLARE   @Waste TABLE (
 	 Detail_Id         Int
 	 , Start_Time        DateTime
 	 , End_Time          DateTime    NULL
 	 , Duration          Float       NULL
 	 , SourcePU          Int         NULL
 	 , MasterUnit        Int         NULL
 	 , Cause_Comment_Id  Int         NULL 	 
 	 , R1_Id 	             Int         NULL
 	 , R2_Id 	             Int         NULL
 	 , R3_Id             Int         NULL
 	 , R4_Id             Int         NULL
 	 , A1_Id 	             Int         NULL
 	 , A2_Id             Int         NULL
 	 , A3_Id             Int         NULL
 	 , A4_Id             Int         NULL
 	 , Fault_Id          Int         NULL
 	 , Crew_Desc         nvarchar(10) NULL
 	 , Shift_Desc        nvarchar(10) NULL
 	 , First_Comment_Id  Int         NULL
 	 , Last_Comment_Id   Int         NULL
 	 , IsNPT tinyint 	 NULL
 	 , ProdId  Int Null
 	 , PPId     Int  Null
 	 , NPTDetId  Int Null
 	 , NPTCatId  Int Null
 	 , Amount    Float Null
 	 , Event_id Int Null
 	 , Waste_Measure_Id Int Null
 	 , Waste_Type_id 	 Int Null
 	 , Unit nVarChar(100) NULL, LocationId int null, Location nVarChar(100) NULL, Fault nVarChar(100) NULL, Product nvarchar(25),
 	 Reason1 nvarchar(50) NULL, Reason2 nvarchar(50) NULL, 	 Reason3 nvarchar(50) NULL, Reason4 nvarchar(50) NULL, Reasons_Completed tinyint NULL, 
 	 Operator nvarchar(50) NULL, EquipId uniqueidentifier null, CategoryId int NULL, Category nVarChar(100) NULL
)
 	 insert into @Waste (Detail_Id, Start_Time, End_Time, Duration, SourcePU, MasterUnit, Cause_Comment_Id,
 	  	  	  	  	  	    R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Fault_Id, Amount, Waste_Measure_Id, Waste_Type_id,
 	  	  	  	  	  	    Crew_Desc, Shift_Desc, Prodid, ppId, IsNPT, NPTDetId, NPTCatId)
 	 exec [dbo].[spBF_WasteGetAll] @StartTime, @EndTime, @UnitList, @InTimeZone, ',', 0, 1
 	 -- Update the Unit, Location, Fault, Reason names, Category
 	 UPDATE d
 	 SET Unit            = u.PU_Desc,
 	  	 LocationId      = Coalesce(d.SourcePU, d.MasterUnit),
 	  	 Location        = Coalesce(l.PU_Desc, u.PU_Desc),
 	  	 Fault           = wef.WEFault_Name,
 	  	 Product         = p.Prod_Code,
 	  	 Reason1 	         = r1.Event_Reason_Name,
 	  	 Reason2 	         = r2.Event_Reason_Name,
 	  	 Reason3 	         = r3.Event_Reason_Name,
 	  	 Reason4 	         = r4.Event_Reason_Name,
 	  	 EquipId         = a1.Origin1EquipmentId,
 	  	 CategoryId 	  	 = erc.ERC_Id,
 	  	 Category 	  	 = erc.ERC_Desc
 	 FROM @Waste d
 	 Join [dbo].[Waste_Event_Details] wed on wed.WED_Id = d.Detail_Id
 	 Left Join [dbo].[Prod_Units] u on u.PU_Id = d.MasterUnit
 	 Left Join [dbo].[Prod_Units] l on l.PU_Id = d.SourcePU
    Left Join [dbo].[Waste_Event_Fault] wef on wef.WEFault_id = d.Fault_id
    Left Join [dbo].[Products] p on p.Prod_Id = d.ProdId  
    Left Join [dbo].[Event_Reasons] r1 on r1.event_reason_id = d.R1_Id  
    Left Join [dbo].[Event_Reasons] r2 on r2.event_reason_id = d.R2_Id  
    Left Join [dbo].[Event_Reasons] r3 on r3.event_reason_id = d.R3_Id  
    Left Join [dbo].[Event_Reasons] r4 on r4.event_reason_id = d.R4_Id
 	 Left Join [dbo].[PAEquipment_Aspect_SOAEquipment] a1 on a1.PU_Id = d.MasterUnit
 	 Left Join [dbo].[Event_Reason_Category_Data] ercd on ercd.Event_Reason_Tree_Data_Id = wed.Event_Reason_Tree_Data_Id
 	 Left Join [dbo].[Event_Reason_Catagories] erc on erc.ERC_Id = ercd.ERC_Id
 	 -- Update the Reasons_Completed flag
 	 UPDATE d
 	 SET Reasons_Completed = Coalesce(ertd.Bottom_Of_Tree, 0)
 	 FROM @Waste d
 	 join [dbo].[Waste_Event_Details] wed on wed.WED_Id = d.Detail_Id
    Left Join [dbo].[Event_Reason_Tree_Data] ertd on ertd.Event_Reason_Tree_Data_Id = wed.Event_Reason_Tree_Data_Id  
 	 -- Lookup Equipment Operators if the table is available
 	 if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[User_Equipment_Assignment]') and OBJECTPROPERTY(id, N'IsTable') = 1)
 	  	 Begin
 	  	  	 UPDATE d
 	  	  	 SET Operator 	 = Coalesce(U.Username, 'Unknown')
 	  	  	 FROM @Waste d
 	  	  	 Left Join [dbo].[User_Equipment_Assignment] ea on ea.EquipmentId = d.MasterUnit
 	  	  	  	  	   and d.End_Time >= ea.StartTime and (d.End_Time < ea.EndTime or ea.EndTime IS NULL)
 	  	  	 Left Join [dbo].[Users] U on U.User_Id = ea.UserId
 	  	 End
 	 Else
 	  	 Begin
 	  	  	 UPDATE @Waste SET Operator = 'Unknown' Where Operator is null
 	  	 End
-------------------------------------------------------------------------------------------------
-- Total Waste
-------------------------------------------------------------------------------------------------
Declare @TotalWaste Float
Select @TotalWaste = 0.0
Select @TotalWaste = @TotalWaste + coalesce((SELECT sum(Amount) From @Waste),0)
if @TotalWaste <= 1 set @TotalWaste = 1
-------------------------------------------------------------------------------------------------
-- Generate Result Sets
-------------------------------------------------------------------------------------------------
Declare @Summary Table (ID1 bigint null, ID2 bigint null,
 	  	  	  	  	  	 Group1 nVarChar(100) null, Group2 nVarChar(100) null,
 	  	  	  	  	  	 Total1 float NULL, Total2 float NULL,
 	  	  	  	  	  	 Ave1 float NULL, Ave2 float NULL,
 	  	  	  	  	  	 PercentTotal1 float NULL, PercentTotal2 float NULL,
 	  	  	  	  	  	 NumberOfEvents1 int NULL, NumberOfEvents2 int NULL)
-------------------------------------------------------------------------------------------------
-- Generate Result Set #1 - Top N Waste by Unit
-------------------------------------------------------------------------------------------------
if Exists(select * from @RSTypes where TypeId = 1)
Begin
 	 Delete from @Summary
 	 insert into @Summary (ID1, Group1, Total1, Ave1, PercentTotal1, NumberOfEvents1)
 	 Select MasterUnit, Unit, sum(Amount), avg(Amount), sum(Amount) / @TotalWaste, count(distinct(Detail_Id))
 	   from @Waste
 	   group by MasterUnit, EquipId, Unit
 	   
 	 update @Summary set Group1 = 'Unidentified' where Group1 is null
 	 
 	 Select Top(@N) ID1                                          as 'UnitId',
 	  	  	  	    Group1                                       as 'Unit',
 	  	  	  	    Total1                                       as 'TotalWaste',
 	  	  	  	    Ave1                                         as 'AveAmount',
 	  	  	  	    convert(decimal(10,2),PercentTotal1 * 100.0) as 'PctTotal',
 	  	  	  	    NumberOfEvents1                              as 'Events',
                    	  	    '' 	  	  	  	  	  	 as 'StartTime',
                    	  	    '' 	  	  	  	  	  	 as 'EndTime'
 	   from @Summary as WasteByUnit
 	   order by Total1 Desc
End
-------------------------------------------------------------------------------------------------
-- Generate Result Set #2 - Top N Waste by Location (Source Unit)
-------------------------------------------------------------------------------------------------
if Exists(select * from @RSTypes where TypeId = 2)
Begin
 	 Delete from @Summary
 	 insert into @Summary (ID1, Group1, Total1, Ave1, PercentTotal1, NumberOfEvents1)
 	 Select LocationId, Location, sum(Amount), avg(Amount), sum(Amount) / @TotalWaste, count(distinct(Detail_Id))
 	   from @Waste
 	   group by LocationId, Location
 	   
 	 update @Summary set Group1 = 'Unidentified' where Group1 is null
 	 
 	 Select Top(@N) ID1                                          as 'LocationId',
 	  	  	  	    Group1                                       as 'Location',
 	  	  	  	    Total1                                       as 'TotalWaste',
 	  	  	  	    Ave1                                         as 'AveAmount',
 	  	  	  	    convert(decimal(10,2),PercentTotal1 * 100.0) as 'PctTotal',
 	  	  	  	    NumberOfEvents1                              as 'Events',
                    	  	    '' 	  	  	  	  	  	 as 'StartTime',
                    	  	    '' 	  	  	  	  	  	 as 'EndTime'
 	   from @Summary as WasteByLocation
 	   order by Total1 Desc
End
-------------------------------------------------------------------------------------------------
-- Generate Result Set #3 - Top N Waste by Fault
-------------------------------------------------------------------------------------------------
if Exists(select * from @RSTypes where TypeId = 3)
Begin
 	 Delete from @Summary
 	 insert into @Summary (ID1, Group1, Total1, Ave1, PercentTotal1, NumberOfEvents1)
 	 Select Fault_id, Fault, sum(Amount), avg(Amount), sum(Amount) / @TotalWaste, count(distinct(Detail_Id))
 	   from @Waste
 	   group by Fault_id, Fault
 	   
 	 update @Summary set Group1 = 'Unidentified' where Group1 is null
 	 
 	 Select Top(@N) ID1                                          as 'FaultId',
 	  	  	  	    Group1                                       as 'Fault',
 	  	  	  	    Total1                                       as 'TotalWaste',
 	  	  	  	    Ave1                                         as 'AveAmount',
 	  	  	  	    convert(decimal(10,2),PercentTotal1 * 100.0) as 'PctTotal',
 	  	  	  	    NumberOfEvents1                              as 'Events',
                    	  	    '' 	  	  	  	  	  	 as 'StartTime',
                    	  	    '' 	  	  	  	  	  	 as 'EndTime'
 	   from @Summary as WasteByFault
 	   order by Total1 Desc
End
-------------------------------------------------------------------------------------------------
-- Generate Result Set #4 - Top N Waste by Reason (Level 1)
-------------------------------------------------------------------------------------------------
if Exists(select * from @RSTypes where TypeId = 4)
Begin
 	 Delete from @Summary
 	 insert into @Summary (ID1, Group1, Total1, Ave1, PercentTotal1, NumberOfEvents1)
 	 Select R1_Id, Reason1, sum(Amount), avg(Amount), sum(Amount) / @TotalWaste, count(distinct(Detail_Id))
 	   from @Waste
 	   group by R1_Id, Reason1
 	   
 	 update @Summary set Group1 = 'Unidentified' where Group1 is null
 	 
 	 Select Top(@N) ID1                                          as 'ReasonId',
 	  	  	  	    Group1                                       as 'Reason',
 	  	  	  	    Total1                                       as 'TotalWaste',
 	  	  	  	    Ave1                                         as 'AveAmount',
 	  	  	  	    convert(decimal(10,2),PercentTotal1 * 100.0) as 'PctTotal',
 	  	  	  	    NumberOfEvents1                              as 'Events',
                    	  	    '' 	  	  	  	  	  	 as 'StartTime',
                    	  	    '' 	  	  	  	  	  	 as 'EndTime'
 	   from @Summary as WasteByReason
 	   order by Total1 Desc
End
-------------------------------------------------------------------------------------------------
-- Generate Result Set #5 - Top N Waste by Shift
-------------------------------------------------------------------------------------------------
if Exists(select * from @RSTypes where TypeId = 5)
Begin
 	 Delete from @Summary
 	 insert into @Summary (Group1, Total1, Ave1, PercentTotal1, NumberOfEvents1)
 	 Select Shift_Desc, sum(Amount), avg(Amount), sum(Amount) / @TotalWaste, count(distinct(Detail_Id))
 	   from @Waste
 	   group by Shift_Desc
 	   
 	 update @Summary set Group1 = 'Unidentified' where Group1 is null
 	 
 	 Select Top(@N) Group1                                       as 'Shift',
 	  	  	  	    Total1                                       as 'TotalWaste',
 	  	  	  	    Ave1                                         as 'AveAmount',
 	  	  	  	    convert(decimal(10,2),PercentTotal1 * 100.0) as 'PctTotal',
 	  	  	  	    NumberOfEvents1                              as 'Events',
                    	  	    '' 	  	  	  	  	  	 as 'StartTime',
                    	  	    '' 	  	  	  	  	  	 as 'EndTime'
 	   from @Summary as WasteByShift
 	   order by Total1 Desc
End
-------------------------------------------------------------------------------------------------
-- Generate Result Set #6 - Top N Waste by Crew
-------------------------------------------------------------------------------------------------
if Exists(select * from @RSTypes where TypeId = 6)
Begin
 	 Delete from @Summary
 	 insert into @Summary (Group1, Total1, Ave1, PercentTotal1, NumberOfEvents1)
 	 Select Crew_Desc, sum(Amount), avg(Amount), sum(Amount) / @TotalWaste, count(distinct(Detail_Id))
 	   from @Waste
 	   group by Crew_Desc
 	   
 	 update @Summary set Group1 = 'Unidentified' where Group1 is null
 	 
 	 Select Top(@N) Group1                                       as 'Crew',
 	  	  	  	    Total1                                       as 'TotalWaste',
 	  	  	  	    Ave1                                         as 'AveAmount',
 	  	  	  	    convert(decimal(10,2),PercentTotal1 * 100.0) as 'PctTotal',
 	  	  	  	    NumberOfEvents1                              as 'Events',
                    	  	    '' 	  	  	  	  	  	 as 'StartTime',
                    	  	    '' 	  	  	  	  	  	 as 'EndTime'
 	   from @Summary as WasteByCrew
 	   order by Total1 Desc
End
-------------------------------------------------------------------------------------------------
-- Generate Result Set #7 - Top N Waste by Operator
-------------------------------------------------------------------------------------------------
if Exists(select * from @RSTypes where TypeId = 7)
Begin
 	 Delete from @Summary
 	 insert into @Summary (Group1, Total1, Ave1, PercentTotal1, NumberOfEvents1)
 	 Select Operator, sum(Amount), avg(Amount), sum(Amount) / @TotalWaste, count(distinct(Detail_Id))
 	   from @Waste
 	   group by Operator
 	   
 	 update @Summary set Group1 = 'Unidentified' where Group1 is null
 	 
 	 Select Top(@N) Group1                                       as 'Operator',
 	  	  	  	    Total1                                       as 'TotalWaste',
 	  	  	  	    Ave1                                         as 'AveAmount',
 	  	  	  	    convert(decimal(10,2),PercentTotal1 * 100.0) as 'PctTotal',
 	  	  	  	    NumberOfEvents1                              as 'Events',
                    	  	    '' 	  	  	  	  	  	 as 'StartTime',
                    	  	    '' 	  	  	  	  	  	 as 'EndTime'
 	   from @Summary as WasteByOperator
 	   order by Total1 Desc
End
-------------------------------------------------------------------------------------------------
-- Generate Result Set #8 - Top N Waste by Product
-------------------------------------------------------------------------------------------------
if Exists(select * from @RSTypes where TypeId = 8)
Begin
 	 Delete from @Summary
 	 insert into @Summary (ID1, Group1, Total1, Ave1, PercentTotal1, NumberOfEvents1)
 	 Select ProdId, Product, sum(Amount), avg(Amount), sum(Amount) / @TotalWaste, count(distinct(Detail_Id))
 	   from @Waste
 	   group by ProdId, Product
 	   
 	 update @Summary set Group1 = 'Unidentified' where Group1 is null
 	 
 	 Select Top(@N) ID1                                          as 'ProductId',
 	  	  	  	    Group1                                       as 'Product',
 	  	  	  	    Total1                                       as 'TotalWaste',
 	  	  	  	    Ave1                                         as 'AveAmount',
 	  	  	  	    convert(decimal(10,2),PercentTotal1 * 100.0) as 'PctTotal',
 	  	  	  	    NumberOfEvents1                              as 'Events',
                    	  	    '' 	  	  	  	  	  	 as 'StartTime',
                    	  	    '' 	  	  	  	  	  	 as 'EndTime'
 	   from @Summary as WasteByProduct
 	   order by Total1 Desc
End
-------------------------------------------------------------------------------------------------
-- Generate Result Set #9 - Unassigned Waste by unit/operator
-------------------------------------------------------------------------------------------------
if Exists(select * from @RSTypes where TypeId = 9)
Begin
 	 Delete from @Summary
 	 insert into @Summary (ID1, Group1, Group2, NumberOfEvents2)
 	 Select MasterUnit, Unit, Operator, Count(distinct(Detail_Id))
 	   from @Waste
 	   where Reasons_Completed = 0
 	   group by MasterUnit, Unit, Operator
 	 update @Summary set NumberOfEvents1 = (select COUNT(distinct(Detail_Id)) from @Waste where Unit = Group1 and Reasons_Completed = 0)
 	   
 	 Select ID1               as 'UnitId',
 	  	    Group1            as 'Unit',
 	  	    Group2            as 'Operator',
 	  	    NumberOfEvents1   as 'UnitEvents',
 	  	    NumberOfEvents2   as 'OperatorEvents',
 	  	    '' 	  	      as 'StartTime',
 	  	    '' 	  	      as 'EndTime'
 	   from @Summary as UnassignedEvents
 	   order by NumberOfEvents1 Desc, NumberOfEvents2 Desc
End
-------------------------------------------------------------------------------------------------
-- Generate Result Set #10 - Top N Waste by Category
-------------------------------------------------------------------------------------------------
if Exists(select * from @RSTypes where TypeId = 10)
Begin
 	 Delete from @Summary
 	 insert into @Summary (ID1, Group1, Total1, Ave1, PercentTotal1, NumberOfEvents1)
 	 Select CategoryId, Category, sum(Amount), avg(Amount), sum(Amount) / @TotalWaste, count(distinct(Detail_Id))
 	   from @Waste
 	   group by CategoryId, Category
 	   
 	 update @Summary set Group1 = 'Unidentified' where Group1 is null
 	 
 	 Select Top(@N) ID1                                          as 'CategoryId',
 	  	  	  	    Group1                                       as 'Category',
 	  	  	  	    Total1                                       as 'TotalWaste',
 	  	  	  	    Ave1                                         as 'AveAmount',
 	  	  	  	    convert(decimal(10,2),PercentTotal1 * 100.0) as 'PctTotal',
 	  	  	  	    NumberOfEvents1                              as 'Events',
                    	  	    '' 	  	  	  	  	  	 as 'StartTime',
                    	  	    '' 	  	  	  	  	  	 as 'EndTime'
 	   from @Summary as WasteByCategory
 	   order by Total1 Desc
End
-------------------------------------------------------------------------------------------------
-- Generate Result Set #99 - Details
-------------------------------------------------------------------------------------------------
if Exists(select * from @RSTypes where TypeId = 99)
Begin
 	 select * from @Waste
End

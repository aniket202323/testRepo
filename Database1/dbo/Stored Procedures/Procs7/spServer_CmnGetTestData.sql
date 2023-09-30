CREATE PROCEDURE dbo.spServer_CmnGetTestData
@VarId int,
@PUId int,
@Time1 datetime,
@Time2 datetime,
@IncludeStartTime int, -- (0 or 1) default 0 
@IncludeEndTime int, -- (0 or 1) default 1
@HonorRejects int,
@Direction nVarChar(10) = NULL,
@NumValuesRequested int = NULL,
@IgnoreNulls int = 1,
@HonorProduct int = 0, -- Only return values where product is the one being made at the time requested
@UseAppliedProduct int = 0, -- Support using applied product
@ProductIdOverride int = NULL -- Null = Use actual product, otherwise use this one as an override
AS
-- Caller will need a Table Variable like the following to execute this sp into
-- 	  	 Declare @TestData Table (EventId int NULL, Result nVarChar(255) NULL, ResultOn datetime, TestId bigint NULL, EntryOn datetime)
-- 	  	 Note: The Result column will contain an errormsg if something goes wrong in this sp,
-- 	  	  	  	  	 so make it big enough
--
Select Event_Id, Result, Result_On, Test_Id, Entry_On
  from dbo.fnServer_CmnGetTestData(@VarId, @PUId, @Time1, @Time2, @IncludeStartTime, @IncludeEndTime, @HonorRejects,
 	  	  	  	  	  	  	  	  	 @Direction, @NumValuesRequested, @IgnoreNulls, @HonorProduct, @UseAppliedProduct, @ProductIdOverride)

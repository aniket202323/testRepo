CREATE Procedure dbo.spDBR_WasteDistribution
@UnitList text = NULL,
@StartTime datetime = NULL,
@EndTime datetime = NULL,
@FilterNonProductiveTime int = 0,
@ProductFilter int = null,
@CrewFilter varchar(10) = null,
@LocationFilter int = NULL,
@FaultFilter varchar(100) = NULL,
@ReasonFilter1 int = NULL,
@ReasonFilter2 int = NULL,
@ReasonFilter3 int = NULL,
@ReasonFilter4 int = NULL,
@ShowTopNBars int = 20,
@InTimeZone varchar(200)=NULL
AS
/*
This procedure is now a wrapper for spDBR_QualityWasteDistribution.
The Quality Distribution and Waste Distribution procedures are identical except Quality returns Pro-Rated data
*/
Declare @ShiftFilter varchar(10), @IsProRated bit
Select @IsProRated = 0
exec spDBR_QualityWasteDistribution @UnitList, @StartTime, @EndTime, @FilterNonProductiveTime, @ProductFilter, @CrewFilter, @LocationFilter, @FaultFilter, @ReasonFilter1, @ReasonFilter2, @ReasonFilter3, @ReasonFilter4, @ShowTopNBars, @ShiftFilter, @IsProRated,@InTimeZone

CREATE PROCEDURE dbo.spServer_CmnGetEventComponentInfo
@Component_Id int,
@Event_Id int OUTPUT,
@Src_Event_Id int OUTPUT,
@Dimension_A float OUTPUT,
@Dimension_X float OUTPUT,
@Dimension_Y float OUTPUT,
@Dimension_Z float OUTPUT,
@StartCoord_A float OUTPUT,
@StartCoord_X float OUTPUT,
@StartCoord_Y float OUTPUT,
@StartCoord_Z float OUTPUT,
@PUId int OUTPUT,
@Timestamp datetime OUTPUT,
@UserId int OUTPUT,
@Found int OUTPUT,
@SourcePUId int OUTPUT,
@PEIId int OUTPUT
AS
Select @Found = NULL
Select @Event_Id = NULL
Select @Src_Event_Id = NULL
Select @Dimension_A = NULL
Select @Dimension_X = NULL
Select @Dimension_Y = NULL
Select @Dimension_Z = NULL
Select @StartCoord_A = NULL
Select @StartCoord_X = NULL
Select @StartCoord_Y = NULL
Select @StartCoord_Z = NULL
Select @PUId = NULL
Select @Timestamp = NULL
Select @UserId = NULL
Select @SourcePUId = NULL
Select @PEIId = NULL
Select @Found  	  	  	  	 = Component_Id,
       @Event_Id  	  	  	 = Event_Id,
       @Src_Event_Id  	 = Source_Event_Id,
       @Dimension_A  	 = Dimension_A,
       @Dimension_X  	 = Dimension_X,
       @Dimension_Y  	 = Dimension_Y,
       @Dimension_Z  	 = Dimension_Z,
       @StartCoord_A  	 = Start_Coordinate_A,
       @StartCoord_X  	 = Start_Coordinate_X,
       @StartCoord_Y  	 = Start_Coordinate_Y,
       @StartCoord_Z  	 = Start_Coordinate_Z,
       @Timestamp  	  	 = Timestamp,
       @UserId  	  	  	  	 = User_Id,
       @PEIId 	  	  	  	  	 = PEI_Id
  From Event_Components
  Where Component_Id = @Component_Id
If (@Found Is NULL)
  Select @Found = 0
Else 
  Begin
    Select @Found = 1
    Select @PUId 	  	  	  	 = PU_Id From Events Where Event_Id = @Event_Id
    Select @SourcePUId 	 = PU_Id From Events Where Event_Id = @Src_Event_Id
  End

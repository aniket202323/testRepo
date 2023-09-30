CREATE PROCEDURE dbo.spServer_DBMgrUpdGrade
  @CurrentId        int          OUTPUT,
  @CurrentPU        int,
  @CurrentProduct   int,
  @Confirmed        int,
  @Start_Year       int     OUTPUT,
  @Start_Month      int      OUTPUT,
  @Start_Day        int      OUTPUT,
  @Start_Hour       int      OUTPUT,
  @Start_Minute     int      OUTPUT,
  @Start_Second     int      OUTPUT,
  @TransNum int, 	  	  	  	 -- NewParam
  @UserId int, 	  	  	  	  	 -- NewParam
  @CommentId int, 	  	  	  	 -- NewParam
  @EventSubTypeId int, 	  	  	  	 -- NewParam
  @End_Year         int     OUTPUT,
  @End_Month        int      OUTPUT,
  @End_Day          int      OUTPUT,
  @End_Hour         int      OUTPUT,
  @End_Minute       int      OUTPUT,
  @End_Second       int      OUTPUT,
  @Product_Code     nVarChar(50)  OUTPUT,
  @ReturnResultSet  int,
  @ModifiedStart    datetime  OUTPUT,
  @ModifiedEnd 	     datetime  OUTPUT,
  @SecondUserId int = NULL -- NewParam
 AS
  Declare @CurrentStart datetime
  Declare @CurrentEnd datetime
  Declare @Rc Int
  EXECUTE spServer_DBMgrEncodeDateTime @Start_Year, @Start_Month, @Start_Day, @Start_Hour, @Start_Minute, @Start_Second, @CurrentStart OUTPUT
  EXECUTE spServer_DBMgrEncodeDateTime @End_Year, @End_Month, @End_Day, @End_Hour, @End_Minute, @End_Second, @CurrentEnd OUTPUT
  Execute @Rc =  spServer_DBMgrUpdGrade2  @CurrentId OUTPUT,@CurrentPU, @CurrentProduct,@Confirmed,@CurrentStart OUTPUT, @TransNum,
 	  	  	  	  	  	  	  	  	  	   @UserId,@CommentId, @EventSubTypeId,@CurrentEnd   OUTPUT, @Product_Code  OUTPUT,
   	  	  	  	  	  	  	  	  	  	   @ReturnResultSet,@ModifiedStart OUTPUT,@ModifiedEnd OUTPUT, @SecondUserId
  EXECUTE spServer_DBMgrDecodeDateTime    @CurrentStart, @Start_Year  OUTPUT,@Start_Month   OUTPUT,@Start_Day OUTPUT, @Start_Hour    OUTPUT,
    	  	  	  	  	  	  	  	  	  	   @Start_Minute  OUTPUT, @Start_Second  OUTPUT
  IF @CurrentEnd IS NULL
    SELECT @End_Year   = 0,@End_Month  = 0, @End_Day    = 0, @End_Hour   = 0, @End_Minute = 0, @End_Second = 0
  ELSE
    EXECUTE spServer_DBMgrDecodeDateTime    @CurrentEnd, @End_Year    OUTPUT, @End_Month   OUTPUT, @End_Day     OUTPUT, @End_Hour    OUTPUT,
       	  	  	  	  	  	  	  	  	  	 @End_Minute  OUTPUT, @End_Second  OUTPUT
  RETURN(@Rc)

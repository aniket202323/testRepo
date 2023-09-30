-- DESCRIPTION: spXLA_UserDefinedEventSUMM_NoProduct_NPT. ECR #27888: mt/4-28-2004
--
CREATE PROCEDURE dbo.spXLA_UserDefinedEventSUMM_NoProduct_NPT
 	   @Start_Time 	  	 DateTime
 	 , @End_Time 	  	 DateTime
 	 , @PU_Id                Int 
 	 , @Event_Subtype_Id 	 Int 	  	  	 
 	 , @SelectR1 	  	 Int
 	 , @SelectR2 	  	 Int
 	 , @SelectR3 	  	 Int
 	 , @SelectR4 	  	 Int
 	 , @SelectA1 	  	 Int
 	 , @SelectA2 	  	 Int
 	 , @SelectA3 	  	 Int
 	 , @SelectA4 	  	 Int
        , @ReasonLevel          Int
 	 , @Crew_Desc 	  	 Varchar(10)
 	 , @Shift_Desc 	  	 Varchar(10)
 	 , @AcknowledgedOnly  	 TinyInt 
 	 , @Username Varchar(50)
 	 , @Langid Int 
AS
DECLARE @TotalUserDefinedEventMinutes  Real
DECLARE @Start_End_Time_Span           Real
DECLARE @QueryType 	                TinyInt
DECLARE @MasterUnit 	                Int
DECLARE @RowCount 	                Int
DECLARE @NOF  Int
 	 --Define Reason Levels
DECLARE @LevelLocation 	 Int 
DECLARE @LevelReason1 	 Int
DECLARE @LevelReason2 	 Int
DECLARE @LevelReason3 	 Int
DECLARE @LevelReason4 	 Int
DECLARE @LevelFault 	 Int
DECLARE @LevelStatus 	 Int
DECLARE @LevelAction1 	 Int
DECLARE @LevelAction2 	 Int
DECLARE @LevelAction3 	 Int
DECLARE @LevelAction4 	 Int
 	 --Define local constants
SELECT @LevelLocation = 0
SELECT @LevelReason1  = 1
SELECT @LevelReason2  = 2
SELECT @LevelReason3  = 3
SELECT @LevelReason4  = 4
SELECT @LevelAction1  = 5
SELECT @LevelAction2  = 6
SELECT @LevelAction3  = 7
SELECT @LevelAction4  = 8
 	 --Needed for Crew,Shift Filters
DECLARE @CrewShift       TinyInt
DECLARE @NoCrewNoShift   TinyInt
DECLARE @HasCrewNoShift  TinyInt
DECLARE @NoCrewHasShift  TinyInt
DECLARE @HasCrewHasShift TinyInt
 	 --Define Crew,Shift Type
SELECT @NoCrewNoShift   = 1
SELECT @HasCrewNoShift  = 2
SELECT @NoCrewHasShift  = 3
SELECT @HasCrewHasShift = 4
If      @Crew_Desc Is NULL AND @Shift_Desc Is NULL     SELECT @CrewShift = @NoCrewNoShift
Else If @Crew_Desc Is NOT NULL AND @Shift_Desc Is NULL SELECT @CrewShift = @HasCrewNoShift
Else If @Crew_Desc Is NULL AND @Shift_Desc Is NOT NULL SELECT @CrewShift = @NoCrewHasShift
Else                                                   SELECT @CrewShift = @HasCrewHasShift
--EndIf:Crew,shift
--DECLARE @UserId 	 Int
--SELECT @UserId = User_Id
--FROM users
--WHERE Username = @Username
--
--EXEC dbo.spXLA_RegisterConnection @UserId,@Langid
CREATE TABLE #MyReport(
 	   ReasonName 	  	  	 Varchar(100)  NULL
 	 , NumberOfOccurances 	  	 Int           NULL
 	 , TotalReasonMinutes  	  	 Real          NULL
 	 , AvgReasonMinutes  	  	 Real          NULL
 	 , TotalUserDefinedEventMinutes 	 Real          NULL
 	 , TotalOperatingMinutes  	 Real          NULL
       )
-- Get All TED Records In Field I Care About
CREATE TABLE #TempUDE (
 	   UDE_Id              Int
        , UDE_Desc            Varchar(1000)
 	 , Start_Time          DateTime
 	 , End_Time            DateTime     NULL
  	 , Duration            real         NULL
 	 , PU_Id               Int          NULL
 	 , Event_Subtype_Id    Int          NULL
        , Reason_Name         Varchar(100) NULL
 	 , R1_Id 	               Int          NULL
 	 , R2_Id 	               Int          NULL
 	 , R3_Id               Int          NULL
 	 , R4_Id               Int          NULL
 	 , A1_Id 	               Int          NULL
 	 , A2_Id               Int          NULL
        , A3_Id               Int          NULL
 	 , A4_Id               Int          NULL
       )
-- Get All The Detail Records We Care About
-- Insert Data Into #TempUDE Temp Table
  If      @CrewShift = @NoCrewNoShift  GOTO NOCREW_NOSHIFT_INSERT
  Else If @CrewShift = @HasCrewNoShift GOTO HASCREW_NOSHIFT_INSERT
  Else If @CrewShift = @NoCrewHasShift GOTO NOCREW_HASSHIFT_INSERT
  Else                                 GOTO HASCREW_HASSHIFT_INSERT
  --EndIf:@CrewShift
NOCREW_NOSHIFT_INSERT:
  If @PU_Id Is NULL  --Analyze Any Production Unit
    If @AcknowledgedOnly = 0
      BEGIN
        INSERT INTO #TempUDE (UDE_Id, UDE_Desc, Start_Time, End_Time, Duration, Event_Subtype_Id, PU_Id, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id)
          SELECT DISTINCT
                 u.UDE_Id, u.UDE_Desc
               , [Start_Time] = Case When u.Start_Time >= u.Start_Time Then u.Start_Time Else u.Start_Time End
               , [End_Time]   = Case When u.End_Time Is NULL Then u.End_Time
                                     When u.End_Time <= u.End_Time Then u.End_Time Else u.End_Time 
                                End
               , u.Duration, u.Event_Subtype_Id, u.PU_Id, u.Cause1, u.Cause2, u.Cause3, u.Cause4, u.Action1, u.Action2, u.Action3, u.Action4
            FROM User_Defined_Events u
            JOIN Prod_Units pu ON (pu.PU_Id = u.PU_Id AND pu.PU_Id <> 0)  
           WHERE u.Start_Time < @End_Time AND ( u.End_Time > @Start_Time OR u.End_Time Is NULL ) 
      END
    Else --@AcknowledgedOnly > 0
      BEGIN
        INSERT INTO #TempUDE (UDE_Id, UDE_Desc, Start_Time, End_Time, Duration, Event_Subtype_Id, PU_Id, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id)
          SELECT DISTINCT
                 u.UDE_Id, u.UDE_Desc
               , [Start_Time] = Case When u.Start_Time >= u.Start_Time Then u.Start_Time Else u.Start_Time End
               , [End_Time]   = Case When u.End_Time Is NULL Then u.End_Time
                                     When u.End_Time <= u.End_Time Then u.End_Time Else u.End_Time 
                                End
               , u.Duration, u.Event_Subtype_Id, u.PU_Id, u.Cause1, u.Cause2, u.Cause3, u.Cause4, u.Action1, u.Action2, u.Action3, u.Action4
            FROM User_Defined_Events u
            JOIN Prod_Units pu ON (pu.PU_Id = u.PU_Id AND pu.PU_Id <> 0)  
           WHERE u.Start_Time < @End_Time AND ( u.End_Time > @Start_Time OR u.End_Time Is NULL ) AND u.Ack = 1
      END
    --EndIf @AcknowledgedOnly...
  Else --@PU_Id Not NULL --Analyze a specific production unit
    If @AcknowledgedOnly = 0
      BEGIN
        INSERT INTO #TempUDE (UDE_Id, UDE_Desc, Start_Time, End_Time, Duration, Event_Subtype_Id, PU_Id, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id)
          SELECT DISTINCT
                 u.UDE_Id, u.UDE_Desc
               , [Start_Time] = Case When u.Start_Time >= u.Start_Time Then u.Start_Time Else u.Start_Time End
               , [End_Time]   = Case When u.End_Time Is NULL Then u.End_Time
                                     When u.End_Time <= u.End_Time Then u.End_Time Else u.End_Time 
                                End
               , u.Duration, u.Event_Subtype_Id, u.PU_Id, u.Cause1, u.Cause2, u.Cause3, u.Cause4, u.Action1, u.Action2, u.Action3, u.Action4
            FROM User_Defined_Events u
            JOIN Prod_Units pu ON (pu.PU_Id = u.PU_Id AND pu.PU_Id <> 0)  
           WHERE u.Start_Time < @End_Time AND ( u.End_Time > @Start_Time OR u.End_Time Is NULL ) AND u.PU_Id = @PU_Id 
      END
    Else --@AcknowledgedOnly > 0
      BEGIN
        INSERT INTO #TempUDE (UDE_Id, UDE_Desc, Start_Time, End_Time, Duration, Event_Subtype_Id, PU_Id, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id)
          SELECT DISTINCT
                 u.UDE_Id, u.UDE_Desc
               , [Start_Time] = Case When u.Start_Time >= u.Start_Time Then u.Start_Time Else u.Start_Time End
               , [End_Time]   = Case When u.End_Time Is NULL Then u.End_Time
                                     When u.End_Time <= u.End_Time Then u.End_Time Else u.End_Time 
                                End
               , u.Duration, u.Event_Subtype_Id, u.PU_Id, u.Cause1, u.Cause2, u.Cause3, u.Cause4, u.Action1, u.Action2, u.Action3, u.Action4
            FROM User_Defined_Events u
            JOIN Prod_Units pu ON (pu.PU_Id = u.PU_Id AND pu.PU_Id <> 0)  
           WHERE u.Start_Time < @End_Time AND ( u.End_Time > @Start_Time OR u.End_Time Is NULL ) AND u.PU_Id = @PU_Id AND u.Ack = 1
      END
    --EndIf --@AcknowledgedOnly...
  --EndIf @PU_Id...
  GOTO CONTINUE_UDE_NOPRODUCT
HASCREW_NOSHIFT_INSERT:
  If @PU_Id Is NULL --Analyze any production unit
    If @AcknowledgedOnly = 0 
      BEGIN
        INSERT INTO #TempUDE (UDE_Id, UDE_Desc, Start_Time, End_Time, Duration, Event_Subtype_Id, PU_Id, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id)
          SELECT DISTINCT
                 u.UDE_Id, u.UDE_Desc
               , [Start_Time] = Case When u.Start_Time >= u.Start_Time Then u.Start_Time Else u.Start_Time End
               , [End_Time]   = Case When u.End_Time Is NULL Then u.End_Time
                                     When u.End_Time <= u.End_Time Then u.End_Time Else u.End_Time 
                                End
               , u.Duration, u.Event_Subtype_Id, u.PU_Id, u.Cause1, u.Cause2, u.Cause3, u.Cause4, u.Action1, u.Action2, u.Action3, u.Action4
            FROM User_Defined_Events u
            JOIN Prod_Units pu ON (pu.PU_Id = u.PU_Id AND pu.PU_Id <> 0)  
            JOIN Crew_Schedule c ON c.PU_Id = u.PU_Id AND c.Crew_Desc = @Crew_Desc
             AND u.Start_Time < c.End_Time AND ( u.End_Time > c.Start_Time OR u.End_Time Is NULL ) AND (c.Start_Time < @End_Time AND c.End_Time > @Start_Time)                          
           WHERE u.Start_Time < @End_Time AND ( u.End_Time > @Start_Time OR u.End_Time Is NULL )
      END
    Else -- @AcknowledgedOnly > 0 Then
      BEGIN
        INSERT INTO #TempUDE (UDE_Id, UDE_Desc, Start_Time, End_Time, Duration, Event_Subtype_Id, PU_Id, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id)
          SELECT DISTINCT
                 u.UDE_Id, u.UDE_Desc
               , [Start_Time] = Case When u.Start_Time >= u.Start_Time Then u.Start_Time Else u.Start_Time End
               , [End_Time]   = Case When u.End_Time Is NULL Then u.End_Time
                                     When u.End_Time <= u.End_Time Then u.End_Time Else u.End_Time 
                                End
               , u.Duration, u.Event_Subtype_Id, u.PU_Id, u.Cause1, u.Cause2, u.Cause3, u.Cause4, u.Action1, u.Action2, u.Action3, u.Action4
            FROM User_Defined_Events u
            JOIN Prod_Units pu ON (pu.PU_Id = u.PU_Id AND pu.PU_Id <> 0)  
            JOIN Crew_Schedule c ON c.PU_Id = u.PU_Id AND c.Crew_Desc = @Crew_Desc
             AND u.Start_Time < c.End_Time AND ( u.End_Time > c.Start_Time OR u.End_Time Is NULL ) AND (c.Start_Time < @End_Time AND c.End_Time > @Start_Time)                          
           WHERE u.Start_Time < @End_Time AND ( u.End_Time > @Start_Time OR u.End_Time Is NULL ) AND u.Ack = 1
      END
    --EndIf; @AcknowledgedOnly...
  Else --@PU_Id not null; Analyze a specific production Unit
    If @AcknowledgedOnly = 0 
      BEGIN
        INSERT INTO #TempUDE (UDE_Id, UDE_Desc, Start_Time, End_Time, Duration, Event_Subtype_Id, PU_Id, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id)
          SELECT DISTINCT
                 u.UDE_Id, u.UDE_Desc
               , [Start_Time] = Case When u.Start_Time >= u.Start_Time Then u.Start_Time Else u.Start_Time End
               , [End_Time]   = Case When u.End_Time Is NULL Then u.End_Time
                                     When u.End_Time <= u.End_Time Then u.End_Time Else u.End_Time 
                                End
               , u.Duration, u.Event_Subtype_Id, u.PU_Id, u.Cause1, u.Cause2, u.Cause3, u.Cause4, u.Action1, u.Action2, u.Action3, u.Action4
            FROM User_Defined_Events u
            JOIN Prod_Units pu ON (pu.PU_Id = u.PU_Id AND pu.PU_Id <> 0)  
            JOIN Crew_Schedule c ON c.PU_Id = u.PU_Id AND c.Crew_Desc = @Crew_Desc
             AND u.Start_Time < c.End_Time AND ( u.End_Time > c.Start_Time OR u.End_Time Is NULL ) AND (c.Start_Time < @End_Time AND c.End_Time > @Start_Time)                          
             AND u.PU_Id = @PU_Id
           WHERE u.Start_Time < @End_Time AND ( u.End_Time > @Start_Time OR u.End_Time Is NULL ) AND u.PU_Id = @PU_Id 
      END
    Else -- @AcknowledgedOnly > 0 Then
      BEGIN
        INSERT INTO #TempUDE (UDE_Id, UDE_Desc, Start_Time, End_Time, Duration, Event_Subtype_Id, PU_Id, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id)
          SELECT DISTINCT
                 u.UDE_Id, u.UDE_Desc
               , [Start_Time] = Case When u.Start_Time >= u.Start_Time Then u.Start_Time Else u.Start_Time End
               , [End_Time]   = Case When u.End_Time Is NULL Then u.End_Time
                                     When u.End_Time <= u.End_Time Then u.End_Time Else u.End_Time 
                                End
               , u.Duration, u.Event_Subtype_Id, u.PU_Id, u.Cause1, u.Cause2, u.Cause3, u.Cause4, u.Action1, u.Action2, u.Action3, u.Action4
            FROM User_Defined_Events u
            JOIN Prod_Units pu ON (pu.PU_Id = u.PU_Id AND pu.PU_Id <> 0)  
            JOIN Crew_Schedule c ON c.PU_Id = u.PU_Id AND c.Crew_Desc = @Crew_Desc
             AND u.Start_Time < c.End_Time AND ( u.End_Time > c.Start_Time OR u.End_Time Is NULL ) AND (c.Start_Time < @End_Time AND c.End_Time > @Start_Time)                          
             AND u.PU_Id = @PU_Id
           WHERE u.Start_Time < @End_Time AND ( u.End_Time > @Start_Time OR u.End_Time Is NULL ) AND u.PU_Id = @PU_Id  AND u.Ack = 1
      END
    --EndIf; @AcknowledgedOnly...
  --EndIf :@PU_Id
  GOTO CONTINUE_UDE_NOPRODUCT
--End HASCREW_NOSHIFT_INSERT:
NOCREW_HASSHIFT_INSERT:
  If @PU_Id Is NULL --analyze any production unit
    If @AcknowledgedOnly = 0 
      BEGIN
        INSERT INTO #TempUDE (UDE_Id, UDE_Desc, Start_Time, End_Time, Duration, Event_Subtype_Id, PU_Id, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id)
          SELECT DISTINCT
                 u.UDE_Id, u.UDE_Desc
               , [Start_Time] = Case When u.Start_Time >= u.Start_Time Then u.Start_Time Else u.Start_Time End
               , [End_Time]   = Case When u.End_Time Is NULL Then u.End_Time
                                     When u.End_Time <= u.End_Time Then u.End_Time Else u.End_Time 
                                End
               , u.Duration, u.Event_Subtype_Id, u.PU_Id, u.Cause1, u.Cause2, u.Cause3, u.Cause4, u.Action1, u.Action2, u.Action3, u.Action4
            FROM User_Defined_Events u
            JOIN Prod_Units pu ON (pu.PU_Id = u.PU_Id AND pu.PU_Id <> 0)  
            JOIN Crew_Schedule c ON c.PU_Id = u.PU_Id AND c.Shift_Desc = @Shift_Desc
             AND u.Start_Time < c.End_Time AND ( u.End_Time > c.Start_Time OR u.End_Time Is NULL ) AND (c.Start_Time < @End_Time AND c.End_Time > @Start_Time)
           WHERE u.Start_Time < @End_Time AND ( u.End_Time > @Start_Time OR u.End_Time Is NULL )
      END
    Else --@AcknowledgedOnly >0
      BEGIN
        INSERT INTO #TempUDE (UDE_Id, UDE_Desc, Start_Time, End_Time, Duration, Event_Subtype_Id, PU_Id, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id)
          SELECT DISTINCT
                 u.UDE_Id, u.UDE_Desc
               , [Start_Time] = Case When u.Start_Time >= u.Start_Time Then u.Start_Time Else u.Start_Time End
               , [End_Time]   = Case When u.End_Time Is NULL Then u.End_Time
                                     When u.End_Time <= u.End_Time Then u.End_Time Else u.End_Time 
                                End
               , u.Duration, u.Event_Subtype_Id, u.PU_Id, u.Cause1, u.Cause2, u.Cause3, u.Cause4, u.Action1, u.Action2, u.Action3, u.Action4
            FROM User_Defined_Events u
            JOIN Prod_Units pu ON (pu.PU_Id = u.PU_Id AND pu.PU_Id <> 0)  
            JOIN Crew_Schedule c ON c.PU_Id = u.PU_Id AND c.Shift_Desc = @Shift_Desc
             AND u.Start_Time < c.End_Time AND ( u.End_Time > c.Start_Time OR u.End_Time Is NULL ) AND (c.Start_Time < @End_Time AND c.End_Time > @Start_Time) 
           WHERE u.Start_Time < @End_Time AND ( u.End_Time > @Start_Time OR u.End_Time Is NULL ) AND u.Ack = 1
      END
    --EndIf;@AcknowledgedOnly...
  Else --@PU_Id not null, analyze a specific production unit
    If @AcknowledgedOnly = 0 
      BEGIN
        INSERT INTO #TempUDE (UDE_Id, UDE_Desc, Start_Time, End_Time, Duration, Event_Subtype_Id, PU_Id, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id)
          SELECT DISTINCT
                 u.UDE_Id, u.UDE_Desc
               , [Start_Time] = Case When u.Start_Time >= u.Start_Time Then u.Start_Time Else u.Start_Time End
               , [End_Time]   = Case When u.End_Time Is NULL Then u.End_Time
                                     When u.End_Time <= u.End_Time Then u.End_Time Else u.End_Time 
                                End
               , u.Duration, u.Event_Subtype_Id, u.PU_Id, u.Cause1, u.Cause2, u.Cause3, u.Cause4, u.Action1, u.Action2, u.Action3, u.Action4
            FROM User_Defined_Events u
            JOIN Prod_Units pu ON (pu.PU_Id = u.PU_Id AND pu.PU_Id <> 0)  
            JOIN Crew_Schedule c ON c.PU_Id = u.PU_Id AND c.Shift_Desc = @Shift_Desc
             AND u.Start_Time < c.End_Time AND ( u.End_Time > c.Start_Time OR u.End_Time Is NULL ) AND (c.Start_Time < @End_Time AND c.End_Time > @Start_Time)                          
             AND u.PU_Id = @PU_Id
           WHERE u.Start_Time < @End_Time AND ( u.End_Time > @Start_Time OR u.End_Time Is NULL ) AND u.PU_Id = @PU_Id 
      END
    Else --@AcknowledgedOnly >0
      BEGIN
        INSERT INTO #TempUDE (UDE_Id, UDE_Desc, Start_Time, End_Time, Duration, Event_Subtype_Id, PU_Id, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id)
          SELECT DISTINCT
                 u.UDE_Id, u.UDE_Desc
               , [Start_Time] = Case When u.Start_Time >= u.Start_Time Then u.Start_Time Else u.Start_Time End
               , [End_Time]   = Case When u.End_Time Is NULL Then u.End_Time
                                     When u.End_Time <= u.End_Time Then u.End_Time Else u.End_Time 
                                End
               , u.Duration, u.Event_Subtype_Id, u.PU_Id, u.Cause1, u.Cause2, u.Cause3, u.Cause4, u.Action1, u.Action2, u.Action3, u.Action4
            FROM User_Defined_Events u
            JOIN Prod_Units pu ON (pu.PU_Id = u.PU_Id AND pu.PU_Id <> 0)  
            JOIN Crew_Schedule c ON c.PU_Id = u.PU_Id AND c.Shift_Desc = @Shift_Desc
             AND u.Start_Time < c.End_Time AND ( u.End_Time > c.Start_Time OR u.End_Time Is NULL ) AND (c.Start_Time < @End_Time AND c.End_Time > @Start_Time)                          
             AND u.PU_Id = @PU_Id
           WHERE u.Start_Time < @End_Time AND ( u.End_Time > @Start_Time OR u.End_Time Is NULL ) AND u.PU_Id = @PU_Id AND u.Ack = 1
      END
    --EndIf;@AcknowledgedOnly...
  --EndIf; @PU_Id...
  GOTO CONTINUE_UDE_NOPRODUCT
HASCREW_HASSHIFT_INSERT:
  If @PU_Id Is NULL --analyze ANY production unit
    If @AcknowledgedOnly = 0 
      BEGIN
        INSERT INTO #TempUDE (UDE_Id, UDE_Desc, Start_Time, End_Time, Duration, Event_Subtype_Id, PU_Id, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id)
          SELECT DISTINCT
                 u.UDE_Id, u.UDE_Desc
               , [Start_Time] = Case When u.Start_Time >= u.Start_Time Then u.Start_Time Else u.Start_Time End
               , [End_Time]   = Case When u.End_Time Is NULL Then u.End_Time
                                     When u.End_Time <= u.End_Time Then u.End_Time Else u.End_Time 
                                End
               , u.Duration, u.Event_Subtype_Id, u.PU_Id, u.Cause1, u.Cause2, u.Cause3, u.Cause4, u.Action1, u.Action2, u.Action3, u.Action4
            FROM User_Defined_Events u
            JOIN Prod_Units pu ON (pu.PU_Id = u.PU_Id AND pu.PU_Id <> 0)  
            JOIN Crew_Schedule c ON c.PU_Id = u.PU_Id AND c.Crew_Desc = @Crew_Desc AND c.Shift_Desc = @Shift_Desc
             AND u.Start_Time < c.End_Time AND ( u.End_Time > c.Start_Time OR u.End_Time Is NULL ) AND (c.Start_Time < @End_Time AND c.End_Time > @Start_Time) 
           WHERE u.Start_Time < @End_Time AND ( u.End_Time > @Start_Time OR u.End_Time Is NULL )
      END
    Else --@AcknowledgedOnly > 0
      BEGIN
        INSERT INTO #TempUDE (UDE_Id, UDE_Desc, Start_Time, End_Time, Duration, Event_Subtype_Id, PU_Id, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id)
          SELECT DISTINCT
                 u.UDE_Id, u.UDE_Desc
               , [Start_Time] = Case When u.Start_Time >= u.Start_Time Then u.Start_Time Else u.Start_Time End
               , [End_Time]   = Case When u.End_Time Is NULL Then u.End_Time
                                     When u.End_Time <= u.End_Time Then u.End_Time Else u.End_Time 
                                End
               , u.Duration, u.Event_Subtype_Id, u.PU_Id, u.Cause1, u.Cause2, u.Cause3, u.Cause4, u.Action1, u.Action2, u.Action3, u.Action4
            FROM User_Defined_Events u
            JOIN Prod_Units pu ON (pu.PU_Id = u.PU_Id AND pu.PU_Id <> 0)  
            JOIN Crew_Schedule c ON c.PU_Id = u.PU_Id AND c.Crew_Desc = @Crew_Desc AND c.Shift_Desc = @Shift_Desc
             AND u.Start_Time < c.End_Time AND ( u.End_Time > c.Start_Time OR u.End_Time Is NULL ) AND (c.Start_Time < @End_Time AND c.End_Time > @Start_Time) 
           WHERE u.Start_Time < @End_Time AND ( u.End_Time > @Start_Time OR u.End_Time Is NULL ) AND u.Ack = 1
      END
    --EndIf;@AcknowledgedOnly...
  Else --@PU_Id not null;analyze A SPECIFIC production unit
    If @AcknowledgedOnly = 0 
      BEGIN
        INSERT INTO #TempUDE (UDE_Id, UDE_Desc, Start_Time, End_Time, Duration, Event_Subtype_Id, PU_Id, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id)
          SELECT DISTINCT
                 u.UDE_Id, u.UDE_Desc
               , [Start_Time] = Case When u.Start_Time >= u.Start_Time Then u.Start_Time Else u.Start_Time End
               , [End_Time]   = Case When u.End_Time Is NULL Then u.End_Time
                                     When u.End_Time <= u.End_Time Then u.End_Time Else u.End_Time 
                                End
               , u.Duration, u.Event_Subtype_Id, u.PU_Id, u.Cause1, u.Cause2, u.Cause3, u.Cause4, u.Action1, u.Action2, u.Action3, u.Action4
            FROM User_Defined_Events u
            JOIN Prod_Units pu ON (pu.PU_Id = u.PU_Id AND pu.PU_Id <> 0)  
            JOIN Crew_Schedule c ON c.PU_Id = u.PU_Id AND c.Crew_Desc = @Crew_Desc AND c.Shift_Desc = @Shift_Desc
             AND u.Start_Time < c.End_Time AND ( u.End_Time > c.Start_Time OR u.End_Time Is NULL ) AND (c.Start_Time < @End_Time AND c.End_Time > @Start_Time)                          
             AND u.PU_Id = @PU_Id
           WHERE u.Start_Time < @End_Time AND ( u.End_Time > @Start_Time OR u.End_Time Is NULL ) AND u.PU_Id = @PU_Id 
      END
    Else --@AcknowledgedOnly > 0
      BEGIN
        INSERT INTO #TempUDE (UDE_Id, UDE_Desc, Start_Time, End_Time, Duration, Event_Subtype_Id, PU_Id, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id)
          SELECT DISTINCT
                 u.UDE_Id, u.UDE_Desc
               , [Start_Time] = Case When u.Start_Time >= u.Start_Time Then u.Start_Time Else u.Start_Time End
               , [End_Time]   = Case When u.End_Time Is NULL Then u.End_Time
                                     When u.End_Time <= u.End_Time Then u.End_Time Else u.End_Time 
                                End
               , u.Duration, u.Event_Subtype_Id, u.PU_Id, u.Cause1, u.Cause2, u.Cause3, u.Cause4, u.Action1, u.Action2, u.Action3, u.Action4
            FROM User_Defined_Events u
            JOIN Prod_Units pu ON (pu.PU_Id = u.PU_Id AND pu.PU_Id <> 0)  
            JOIN Crew_Schedule c ON c.PU_Id = u.PU_Id AND c.Crew_Desc = @Crew_Desc AND c.Shift_Desc = @Shift_Desc
             AND u.Start_Time < c.End_Time AND ( u.End_Time > c.Start_Time OR u.End_Time Is NULL ) AND (c.Start_Time < @End_Time AND c.End_Time > @Start_Time)                          
             AND u.PU_Id = @PU_Id
           WHERE u.Start_Time < @End_Time AND ( u.End_Time > @Start_Time OR u.End_Time Is NULL ) AND u.PU_Id = @PU_Id AND u.Ack = 1
      END
    --EndIf;@AcknowledgedOnly...
  --EndIf;@PU_Id...
  GOTO CONTINUE_UDE_NOPRODUCT
CONTINUE_UDE_NOPRODUCT:
  -- Clean up invalid PU_Id and Event_Subtype_Id
  DELETE FROM #TempUDE WHERE PU_Id = 0 OR Event_Subtype_Id = 0
  --Delete Rows that don't match specified filters
  If @Event_Subtype_Id Is Not NULL
      DELETE FROM #TempUDE WHERE Event_Subtype_Id Is NULL OR Event_Subtype_Id <> @Event_Subtype_Id
  --EndIf
  If @SelectR1 Is Not NULL  DELETE FROM #TempUDE WHERE R1_Id Is NULL Or R1_Id <> @SelectR1  
  If @SelectR2 Is Not NULL  DELETE FROM #TempUDE WHERE R2_Id Is NULL Or R2_Id <> @SelectR2
  If @SelectR3 Is Not NULL  DELETE FROM #TempUDE WHERE R3_Id Is NULL Or R3_Id <> @SelectR3
  If @SelectR4 Is Not NULL  DELETE FROM #TempUDE WHERE R4_Id Is NULL Or R4_Id <> @SelectR4
  If @SelectA1 Is NOT NULL  DELETE FROM #TempUDE WHERE A1_Id Is NULL OR A1_Id <> @SelectA1
  If @SelectA2 Is NOT NULL  DELETE FROM #TempUDE WHERE A2_Id Is NULL OR A2_Id <> @SelectA2
  If @SelectA3 Is NOT NULL  DELETE FROM #TempUDE WHERE A3_Id Is NULL OR A3_Id <> @SelectA3
  If @SelectA4 Is NOT NULL  DELETE FROM #TempUDE WHERE A4_Id Is NULL OR A4_Id <> @SelectA4
  -- Trim off Start And End Times to user-specified time range
  UPDATE #TempUDE SET Start_Time = @Start_Time WHERE Start_Time < @Start_Time
  UPDATE #TempUDE SET End_Time = @End_Time WHERE End_Time > @End_Time OR End_Time Is NULL
  UPDATE #TempUDE SET Duration = DATEDIFF(ss, start_time, end_time) / 60.0
  SELECT @Start_End_Time_Span = 0
  SELECT @Start_End_Time_Span = (DATEDIFF(ss, @Start_Time, @End_Time) / 60.0) - @Start_End_Time_Span
  --Update Reasons...
  UPDATE #TempUDE
    SET Reason_Name = Case @ReasonLevel
                        When @LevelLocation Then PU.PU_Desc 	  	  	 
                        When @LevelReason1  Then R1.Event_Reason_Name
                        When @LevelReason2  Then R2.Event_Reason_Name
                        When @LevelReason3  Then R3.Event_Reason_Name
                        When @LevelReason4  Then R4.Event_Reason_Name
                        When @LevelAction1  Then A1.Event_Reason_Name
                        When @LevelAction2  Then A2.Event_Reason_Name
                        When @LevelAction3  Then A3.Event_Reason_Name
                        When @LevelAction4  Then A4.Event_Reason_Name
                      End
    FROM #TempUDE D
    LEFT OUTER JOIN Prod_Units PU ON PU.PU_Id = D.PU_Id 
    LEFT OUTER JOIN Event_Reasons R1 ON (D.R1_Id = R1.Event_Reason_Id)
    LEFT OUTER JOIN Event_Reasons R2 ON (D.R2_Id = R2.Event_Reason_Id)
    LEFT OUTER JOIN Event_Reasons R3 ON (D.R3_Id = R3.Event_Reason_Id)
    LEFT OUTER JOIN Event_Reasons R4 ON (D.R4_Id = R4.Event_Reason_Id)
    LEFT OUTER JOIN Event_Reasons A1 ON (D.A1_Id = A1.Event_Reason_Id)
    LEFT OUTER JOIN Event_Reasons A2 ON (D.A2_Id = A2.Event_Reason_Id)
    LEFT OUTER JOIN Event_Reasons A3 ON (D.A3_Id = A3.Event_Reason_Id)
    LEFT OUTER JOIN Event_Reasons A4 ON (D.A4_Id = A4.Event_Reason_Id)
----------------------------------------
 	 -------NPT-------
----------------------------------------
DECLARE @NPTCount int
DECLARE @Periods_NPT TABLE ( PeriodId int IDENTITY(1,1) PRIMARY KEY NONCLUSTERED,StartTime Datetime, EndTime Datetime,NPDuration int)
      INSERT INTO @Periods_NPT ( Starttime,Endtime)
      SELECT      
                  StartTime               = CASE      WHEN np.Start_Time < @Start_Time THEN @Start_Time
                                                ELSE np.Start_Time
                                                END,
                  EndTime           = CASE      WHEN np.End_Time > @End_time THEN @End_time
                                                ELSE np.End_Time
                                                END
      FROM dbo.NonProductive_Detail np WITH (NOLOCK)
            JOIN dbo.Event_Reason_Category_Data ercd WITH (NOLOCK) ON      ercd.Event_Reason_Tree_Data_Id = np.Event_Reason_Tree_Data_Id
                                                                                                      AND ercd.ERC_Id = (SELECT Non_Productive_Category FROM prod_units where PU_id =@PU_Id)
      WHERE PU_Id = @PU_id
                  AND np.Start_Time < @End_time
                  AND np.End_Time > @Start_Time
SELECT @NPTCount = 0
-------NPT OF Downtime-------
-- Case 1 :  Downtime    St---------------------End
-- 	  	  	  NPT   St--------------End
UPDATE #TempUDE SET Start_Time = n.Endtime
FROM #TempUDE  JOIN @Periods_NPT n ON (Start_Time > n.StartTime AND End_time > n.EndTime AND Start_Time < n.EndTime)
-- Case 2 :  Downtime    St---------------------End
-- 	  	  	  NPT 	  	  	  	  	 St--------------End
UPDATE #TempUDE SET End_Time = n.Starttime FROM 	 #TempUDE 	  	    
JOIN @Periods_NPT n ON (Start_Time < n.StartTime AND End_Time < n.Endtime AND End_Time > n.StartTime)
 	  	 
-- Case 3 :  Downtime   St-----------------------End
-- 	  	  	  NPT   St-------------------------------End
UPDATE #TempUDE SET Start_Time = End_Time,
 	  	  	  	  	 @NPTCount = @NPTCount + 1
FROM 	 #TempUDE  	  	    
JOIN @Periods_NPT n ON( (Start_Time BETWEEN n.StartTime AND n.EndTime) AND (End_time BETWEEN n.StartTime AND n.EndTime))
Update #TempUDE Set Duration =DateDiff(ss,Start_Time,End_Time)/60.0
-- Case 4 :  Downtime   St-----------------------End
-- 	  	  	  NPT 	  	    St-----------------End
UPDATE #TempUDE  SET Duration = (Datediff(ss,Start_Time,End_Time) - DateDiff(ss,n.StartTime,n.EndTime))/60.0
FROM #TempUDE  JOIN @Periods_NPT n ON( (n.StartTime BETWEEN Start_Time AND End_Time) AND (n.Endtime BETWEEN Start_Time AND End_Time))
------------------------------------------
SELECT @TotalUserDefinedEventMinutes = SUM(Duration) from #TempUDE
SELECT @NOF = COUNT(Duration)- @NPTCount from #TempUDE
--Print  @NPTCount 	 
--Print @NOF
--SELECT * FROM #TempUDE
--SELECT * FROM  @Periods_NPT
--  UPDATE #TempUDE SET Reason_Name = dbo.fnDBTranslate(@LangId, 38333, 'Unspecified') WHERE Reason_Name Is NULL
  SELECT @RowCount = 0
  SELECT @RowCount = Count(*) FROM #TempUDE
  If @RowCount = 0
    BEGIN
      INSERT INTO #MyReport (TotalOperatingMinutes) VALUES ( @Start_End_Time_Span )
      GOTO RETURN_RESULT_SET
    END
  --EndIf:@RowCount
  -- Populate #MyReport with approprate data
  INSERT INTO #MyReport( ReasonName , 
 	  	  	  	  	  	  NumberOfOccurances, 
 	  	  	  	  	  	  TotalReasonMinutes ,
 	  	  	  	          AvgReasonMinutes,
 	  	                  TotalUserDefinedEventMinutes,
 	  	  	  	  	  	  TotalOperatingMinutes)
    --SELECT               Reason_Name, COUNT(Duration)-@NPTCount 	 ,   Total_Duration = SUM(Duration), (SUM(Duration) / COUNT(Duration)-@NPTCount), @TotalUserDefinedEventMinutes, @Start_End_Time_Span
 	 SELECT               Reason_Name, @NOF  	 ,   Total_Duration = SUM(Duration), (SUM(Duration) / @NOF), @TotalUserDefinedEventMinutes, @Start_End_Time_Span
      FROM #TempUDE
  GROUP BY Reason_Name
  ORDER BY Total_Duration DESC
RETURN_RESULT_SET:
  SELECT * FROM #MyReport
  GOTO DROP_TEMP_TABLES
DROP_TEMP_TABLES:
  DROP TABLE #TempUDE
  DROP TABLE #MyReport
--DELETE FROM User_Connections Where SPID = @@SPID and User_Id = @UserId and Language_Id = @LangId

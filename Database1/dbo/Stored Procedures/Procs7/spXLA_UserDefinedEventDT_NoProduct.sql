-- DESCRIPTION: spXLA_UserDefinedEventDT_NoProduct. ECR #27889: mt/4-27-2004
--
CREATE PROCEDURE dbo.spXLA_UserDefinedEventDT_NoProduct
 	   @Start_Time 	  	 DateTime
 	 , @End_Time 	  	 DateTime
 	 , @PU_Id                Int       -- Location 
 	 , @Event_Subtype_Id 	 Int 	  	  	 
 	 , @SelectR1 	  	 Int
 	 , @SelectR2 	  	 Int
 	 , @SelectR3 	  	 Int
 	 , @SelectR4 	  	 Int
 	 , @SelectA1 	  	 Int
 	 , @SelectA2 	  	 Int
 	 , @SelectA3 	  	 Int
 	 , @SelectA4 	  	 Int
 	 , @Crew_Desc 	  	 Varchar(10)
 	 , @Shift_Desc 	  	 Varchar(10)
 	 , @AcknowledgedOnly  	 TinyInt 
 	 , @TimeSort 	  	 TinyInt = NULL
 	 , @Username Varchar(50) = NULL
 	 , @Langid Int = 0
AS
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
DECLARE @Unspecified varchar(50)
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
--
--SELECT @Unspecified = dbo.fnDBTranslate(@LangId, 38333, 'Unspecified')
-- Get All TED Records In Field I Care About
CREATE TABLE #TempUDE (
 	   UDE_Id              Int
        , UDE_Desc            Varchar(1000)
 	 , Start_Time          DateTime
 	 , End_Time            DateTime    NULL
  	 , Duration            real        NULL
 	 , Event_Subtype_Id    Int         NULL
 	 , PU_Id               Int         NULL
 	 , R1_Id 	               Int         NULL
 	 , R2_Id 	               Int         NULL
 	 , R3_Id               Int         NULL
 	 , R4_Id               Int         NULL
 	 , A1_Id 	               Int         NULL
 	 , A2_Id               Int         NULL
        , A3_Id               Int         NULL
 	 , A4_Id               Int         NULL
 	 , Crew_Desc           Varchar(10) NULL
 	 , Shift_Desc          Varchar(10) NULL
        , Ack_By              Int         NULL
        , Ack_On              DateTime    NULL
 	 , Research_User_Id    Int         NULL
 	 , Research_Status_Id  Int         NULL
 	 , Modified_On         DateTime    NULL
 	 , Research_Open_Date  DateTime    NULL
 	 , Research_Close_Date DateTime    NULL
 	 , Comment_Id          Int         NULL
 	 , Cause_Comment_Id    Int         NULL
 	 , Action_Comment_Id   Int         NULL
 	 , Research_Comment_Id Int         NULL
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
        INSERT INTO #TempUDE (UDE_Id, UDE_Desc, Start_Time, End_Time, Duration, Event_Subtype_Id, PU_Id, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Ack_By, Ack_On, Research_User_Id, Research_Status_Id, Modified_On, Research_Open_Date, Research_Close_Date, Comment_Id, Cause_Comment_Id, Action_Comment_Id, Research_Comment_Id)
          SELECT DISTINCT
                 u.UDE_Id, u.UDE_Desc
               , [Start_Time] = Case When u.Start_Time >= u.Start_Time Then u.Start_Time Else u.Start_Time End
               , [End_Time]   = Case When u.End_Time Is NULL Then u.End_Time
                                     When u.End_Time <= u.End_Time Then u.End_Time Else u.End_Time 
                                End
               , u.Duration, u.Event_Subtype_Id, u.PU_Id, u.Cause1, u.Cause2, u.Cause3, u.Cause4, u.Action1, u.Action2, u.Action3, u.Action4, u.Ack_By, u.Ack_On, u.Research_User_Id, u.Research_Status_Id, u.Modified_On, u.Research_Open_Date, u.Research_Close_Date, u.Comment_Id, u.Cause_Comment_Id, u.Action_Comment_Id, u.Research_Comment_Id
            FROM User_Defined_Events u
            JOIN Prod_Units pu ON (pu.PU_Id = u.PU_Id AND pu.PU_Id <> 0)  
           WHERE u.Start_Time < @End_Time AND ( u.End_Time > @Start_Time OR u.End_Time Is NULL ) 
      END
    Else --@AcknowledgedOnly > 0
      BEGIN
        INSERT INTO #TempUDE (UDE_Id, UDE_Desc, Start_Time, End_Time, Duration, Event_Subtype_Id, PU_Id, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Ack_By, Ack_On, Research_User_Id, Research_Status_Id, Modified_On, Research_Open_Date, Research_Close_Date, Comment_Id, Cause_Comment_Id, Action_Comment_Id, Research_Comment_Id)
          SELECT DISTINCT
                 u.UDE_Id, u.UDE_Desc
               , [Start_Time] = Case When u.Start_Time >= u.Start_Time Then u.Start_Time Else u.Start_Time End
               , [End_Time]   = Case When u.End_Time Is NULL Then u.End_Time
                                     When u.End_Time <= u.End_Time Then u.End_Time Else u.End_Time 
                                End
               , u.Duration, u.Event_Subtype_Id, u.PU_Id, u.Cause1, u.Cause2, u.Cause3, u.Cause4, u.Action1, u.Action2, u.Action3, u.Action4, u.Ack_By, u.Ack_On, u.Research_User_Id, u.Research_Status_Id, u.Modified_On, u.Research_Open_Date, u.Research_Close_Date, u.Comment_Id, u.Cause_Comment_Id, u.Action_Comment_Id, u.Research_Comment_Id
            FROM User_Defined_Events u
            JOIN Prod_Units pu ON (pu.PU_Id = u.PU_Id AND pu.PU_Id <> 0)  
           WHERE u.Start_Time < @End_Time AND ( u.End_Time > @Start_Time OR u.End_Time Is NULL ) AND u.Ack = 1
      END
    --EndIf @AcknowledgedOnly...
  Else --@PU_Id Not NULL --Analyze a specific production unit
    If @AcknowledgedOnly = 0
      BEGIN
        INSERT INTO #TempUDE (UDE_Id, UDE_Desc, Start_Time, End_Time, Duration, Event_Subtype_Id, PU_Id, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Ack_By, Ack_On, Research_User_Id, Research_Status_Id, Modified_On, Research_Open_Date, Research_Close_Date, Comment_Id, Cause_Comment_Id, Action_Comment_Id, Research_Comment_Id)
          SELECT DISTINCT
                 u.UDE_Id, u.UDE_Desc
               , [Start_Time] = Case When u.Start_Time >= u.Start_Time Then u.Start_Time Else u.Start_Time End
               , [End_Time]   = Case When u.End_Time Is NULL Then u.End_Time
                                     When u.End_Time <= u.End_Time Then u.End_Time Else u.End_Time 
                                End
               , u.Duration, u.Event_Subtype_Id, u.PU_Id, u.Cause1, u.Cause2, u.Cause3, u.Cause4, u.Action1, u.Action2, u.Action3, u.Action4, u.Ack_By, u.Ack_On, u.Research_User_Id, u.Research_Status_Id, u.Modified_On, u.Research_Open_Date, u.Research_Close_Date, u.Comment_Id, u.Cause_Comment_Id, u.Action_Comment_Id, u.Research_Comment_Id
            FROM User_Defined_Events u
            JOIN Prod_Units pu ON (pu.PU_Id = u.PU_Id AND pu.PU_Id <> 0)  
           WHERE u.Start_Time < @End_Time AND ( u.End_Time > @Start_Time OR u.End_Time Is NULL ) AND u.PU_Id = @PU_Id 
      END
    Else --@AcknowledgedOnly > 0
      BEGIN
        INSERT INTO #TempUDE (UDE_Id, UDE_Desc, Start_Time, End_Time, Duration, Event_Subtype_Id, PU_Id, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Ack_By, Ack_On, Research_User_Id, Research_Status_Id, Modified_On, Research_Open_Date, Research_Close_Date, Comment_Id, Cause_Comment_Id, Action_Comment_Id, Research_Comment_Id)
          SELECT DISTINCT
                 u.UDE_Id, u.UDE_Desc
               , [Start_Time] = Case When u.Start_Time >= u.Start_Time Then u.Start_Time Else u.Start_Time End
               , [End_Time]   = Case When u.End_Time Is NULL Then u.End_Time
                                     When u.End_Time <= u.End_Time Then u.End_Time Else u.End_Time 
                                End
               , u.Duration, u.Event_Subtype_Id, u.PU_Id, u.Cause1, u.Cause2, u.Cause3, u.Cause4, u.Action1, u.Action2, u.Action3, u.Action4, u.Ack_By, u.Ack_On, u.Research_User_Id, u.Research_Status_Id, u.Modified_On, u.Research_Open_Date, u.Research_Close_Date, u.Comment_Id, u.Cause_Comment_Id, u.Action_Comment_Id, u.Research_Comment_Id
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
        INSERT INTO #TempUDE (UDE_Id, UDE_Desc, Start_Time, End_Time, Duration, Event_Subtype_Id, PU_Id, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Crew_Desc, Shift_Desc, Ack_By, Ack_On, Research_User_Id, Research_Status_Id, Modified_On, Research_Open_Date, Research_Close_Date, Comment_Id, Cause_Comment_Id, Action_Comment_Id, Research_Comment_Id)
          SELECT DISTINCT
                 u.UDE_Id, u.UDE_Desc
               , [Start_Time] = Case When u.Start_Time >= u.Start_Time Then u.Start_Time Else u.Start_Time End
               , [End_Time]   = Case When u.End_Time Is NULL Then u.End_Time
                                     When u.End_Time <= u.End_Time Then u.End_Time Else u.End_Time 
                                End
               , u.Duration, u.Event_Subtype_Id, u.PU_Id, u.Cause1, u.Cause2, u.Cause3, u.Cause4, u.Action1, u.Action2, u.Action3, u.Action4, c.Crew_Desc, c.Shift_Desc, u.Ack_By, u.Ack_On, u.Research_User_Id, u.Research_Status_Id, u.Modified_On, u.Research_Open_Date, u.Research_Close_Date, u.Comment_Id, u.Cause_Comment_Id, u.Action_Comment_Id, u.Research_Comment_Id
            FROM User_Defined_Events u
            JOIN Prod_Units pu ON (pu.PU_Id = u.PU_Id AND pu.PU_Id <> 0)  
            JOIN Crew_Schedule c ON c.PU_Id = u.PU_Id AND c.Crew_Desc = @Crew_Desc
             AND u.Start_Time < c.End_Time AND ( u.End_Time > c.Start_Time OR u.End_Time Is NULL ) AND (c.Start_Time < @End_Time AND c.End_Time > @Start_Time)                          
           WHERE u.Start_Time < @End_Time AND ( u.End_Time > @Start_Time OR u.End_Time Is NULL )
      END
    Else -- @AcknowledgedOnly > 0 Then
      BEGIN
        INSERT INTO #TempUDE (UDE_Id, UDE_Desc, Start_Time, End_Time, Duration, Event_Subtype_Id, PU_Id, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Crew_Desc, Shift_Desc, Ack_By, Ack_On, Research_User_Id, Research_Status_Id, Modified_On, Research_Open_Date, Research_Close_Date, Comment_Id, Cause_Comment_Id, Action_Comment_Id, Research_Comment_Id)
          SELECT DISTINCT
                 u.UDE_Id, u.UDE_Desc
               , [Start_Time] = Case When u.Start_Time >= u.Start_Time Then u.Start_Time Else u.Start_Time End
               , [End_Time]   = Case When u.End_Time Is NULL Then u.End_Time
                                     When u.End_Time <= u.End_Time Then u.End_Time Else u.End_Time 
                                End
               , u.Duration, u.Event_Subtype_Id, u.PU_Id, u.Cause1, u.Cause2, u.Cause3, u.Cause4, u.Action1, u.Action2, u.Action3, u.Action4, c.Crew_Desc, c.Shift_Desc, u.Ack_By, u.Ack_On, u.Research_User_Id, u.Research_Status_Id, u.Modified_On, u.Research_Open_Date, u.Research_Close_Date, u.Comment_Id, u.Cause_Comment_Id, u.Action_Comment_Id, u.Research_Comment_Id
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
        INSERT INTO #TempUDE (UDE_Id, UDE_Desc, Start_Time, End_Time, Duration, Event_Subtype_Id, PU_Id, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Crew_Desc, Shift_Desc, Ack_By, Ack_On, Research_User_Id, Research_Status_Id, Modified_On, Research_Open_Date, Research_Close_Date, Comment_Id, Cause_Comment_Id, Action_Comment_Id, Research_Comment_Id)
          SELECT DISTINCT
                 u.UDE_Id, u.UDE_Desc
               , [Start_Time] = Case When u.Start_Time >= u.Start_Time Then u.Start_Time Else u.Start_Time End
               , [End_Time]   = Case When u.End_Time Is NULL Then u.End_Time
                                     When u.End_Time <= u.End_Time Then u.End_Time Else u.End_Time 
                                End
               , u.Duration, u.Event_Subtype_Id, u.PU_Id, u.Cause1, u.Cause2, u.Cause3, u.Cause4, u.Action1, u.Action2, u.Action3, u.Action4, c.Crew_Desc, c.Shift_Desc, u.Ack_By, u.Ack_On, u.Research_User_Id, u.Research_Status_Id, u.Modified_On, u.Research_Open_Date, u.Research_Close_Date, u.Comment_Id, u.Cause_Comment_Id, u.Action_Comment_Id, u.Research_Comment_Id
            FROM User_Defined_Events u
            JOIN Prod_Units pu ON (pu.PU_Id = u.PU_Id AND pu.PU_Id <> 0)  
            JOIN Crew_Schedule c ON c.PU_Id = u.PU_Id AND c.Crew_Desc = @Crew_Desc
             AND u.Start_Time < c.End_Time AND ( u.End_Time > c.Start_Time OR u.End_Time Is NULL ) AND (c.Start_Time < @End_Time AND c.End_Time > @Start_Time)                          
             AND u.PU_Id = @PU_Id
           WHERE u.Start_Time < @End_Time AND ( u.End_Time > @Start_Time OR u.End_Time Is NULL ) AND u.PU_Id = @PU_Id 
      END
    Else -- @AcknowledgedOnly > 0 Then
      BEGIN
        INSERT INTO #TempUDE (UDE_Id, UDE_Desc, Start_Time, End_Time, Duration, Event_Subtype_Id, PU_Id, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Crew_Desc, Shift_Desc, Ack_By, Ack_On, Research_User_Id, Research_Status_Id, Modified_On, Research_Open_Date, Research_Close_Date, Comment_Id, Cause_Comment_Id, Action_Comment_Id, Research_Comment_Id)
          SELECT DISTINCT
                 u.UDE_Id, u.UDE_Desc
               , [Start_Time] = Case When u.Start_Time >= u.Start_Time Then u.Start_Time Else u.Start_Time End
               , [End_Time]   = Case When u.End_Time Is NULL Then u.End_Time
                                     When u.End_Time <= u.End_Time Then u.End_Time Else u.End_Time 
                                End
               , u.Duration, u.Event_Subtype_Id, u.PU_Id, u.Cause1, u.Cause2, u.Cause3, u.Cause4, u.Action1, u.Action2, u.Action3, u.Action4, c.Crew_Desc, c.Shift_Desc, u.Ack_By, u.Ack_On, u.Research_User_Id, u.Research_Status_Id, u.Modified_On, u.Research_Open_Date, u.Research_Close_Date, u.Comment_Id, u.Cause_Comment_Id, u.Action_Comment_Id, u.Research_Comment_Id
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
        INSERT INTO #TempUDE (UDE_Id, UDE_Desc, Start_Time, End_Time, Duration, Event_Subtype_Id, PU_Id, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Crew_Desc, Shift_Desc, Ack_By, Ack_On, Research_User_Id, Research_Status_Id, Modified_On, Research_Open_Date, Research_Close_Date, Comment_Id, Cause_Comment_Id, Action_Comment_Id, Research_Comment_Id)
          SELECT DISTINCT
                 u.UDE_Id, u.UDE_Desc
               , [Start_Time] = Case When u.Start_Time >= u.Start_Time Then u.Start_Time Else u.Start_Time End
               , [End_Time]   = Case When u.End_Time Is NULL Then u.End_Time
                                     When u.End_Time <= u.End_Time Then u.End_Time Else u.End_Time 
                                End
               , u.Duration, u.Event_Subtype_Id, u.PU_Id, u.Cause1, u.Cause2, u.Cause3, u.Cause4, u.Action1, u.Action2, u.Action3, u.Action4, c.Crew_Desc, c.Shift_Desc, u.Ack_By, u.Ack_On, u.Research_User_Id, u.Research_Status_Id, u.Modified_On, u.Research_Open_Date, u.Research_Close_Date, u.Comment_Id, u.Cause_Comment_Id, u.Action_Comment_Id, u.Research_Comment_Id
            FROM User_Defined_Events u
            JOIN Prod_Units pu ON (pu.PU_Id = u.PU_Id AND pu.PU_Id <> 0)  
            JOIN Crew_Schedule c ON c.PU_Id = u.PU_Id AND c.Shift_Desc = @Shift_Desc
             AND u.Start_Time < c.End_Time AND ( u.End_Time > c.Start_Time OR u.End_Time Is NULL ) AND (c.Start_Time < @End_Time AND c.End_Time > @Start_Time)
           WHERE u.Start_Time < @End_Time AND ( u.End_Time > @Start_Time OR u.End_Time Is NULL )
      END
    Else --@AcknowledgedOnly >0
      BEGIN
        INSERT INTO #TempUDE (UDE_Id, UDE_Desc, Start_Time, End_Time, Duration, Event_Subtype_Id, PU_Id, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Crew_Desc, Shift_Desc, Ack_By, Ack_On, Research_User_Id, Research_Status_Id, Modified_On, Research_Open_Date, Research_Close_Date, Comment_Id, Cause_Comment_Id, Action_Comment_Id, Research_Comment_Id)
          SELECT DISTINCT
                 u.UDE_Id, u.UDE_Desc
               , [Start_Time] = Case When u.Start_Time >= u.Start_Time Then u.Start_Time Else u.Start_Time End
               , [End_Time]   = Case When u.End_Time Is NULL Then u.End_Time
                                     When u.End_Time <= u.End_Time Then u.End_Time Else u.End_Time 
                                End
               , u.Duration, u.Event_Subtype_Id, u.PU_Id, u.Cause1, u.Cause2, u.Cause3, u.Cause4, u.Action1, u.Action2, u.Action3, u.Action4, c.Crew_Desc, c.Shift_Desc, u.Ack_By, u.Ack_On, u.Research_User_Id, u.Research_Status_Id, u.Modified_On, u.Research_Open_Date, u.Research_Close_Date, u.Comment_Id, u.Cause_Comment_Id, u.Action_Comment_Id, u.Research_Comment_Id
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
        INSERT INTO #TempUDE (UDE_Id, UDE_Desc, Start_Time, End_Time, Duration, Event_Subtype_Id, PU_Id, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Crew_Desc, Shift_Desc, Ack_By, Ack_On, Research_User_Id, Research_Status_Id, Modified_On, Research_Open_Date, Research_Close_Date, Comment_Id, Cause_Comment_Id, Action_Comment_Id, Research_Comment_Id)
          SELECT DISTINCT
                 u.UDE_Id, u.UDE_Desc
               , [Start_Time] = Case When u.Start_Time >= u.Start_Time Then u.Start_Time Else u.Start_Time End
               , [End_Time]   = Case When u.End_Time Is NULL Then u.End_Time
                                     When u.End_Time <= u.End_Time Then u.End_Time Else u.End_Time 
                                End
               , u.Duration, u.Event_Subtype_Id, u.PU_Id, u.Cause1, u.Cause2, u.Cause3, u.Cause4, u.Action1, u.Action2, u.Action3, u.Action4, c.Crew_Desc, c.Shift_Desc, u.Ack_By, u.Ack_On, u.Research_User_Id, u.Research_Status_Id, u.Modified_On, u.Research_Open_Date, u.Research_Close_Date, u.Comment_Id, u.Cause_Comment_Id, u.Action_Comment_Id, u.Research_Comment_Id
            FROM User_Defined_Events u
            JOIN Prod_Units pu ON (pu.PU_Id = u.PU_Id AND pu.PU_Id <> 0)  
            JOIN Crew_Schedule c ON c.PU_Id = u.PU_Id AND c.Shift_Desc = @Shift_Desc
             AND u.Start_Time < c.End_Time AND ( u.End_Time > c.Start_Time OR u.End_Time Is NULL ) AND (c.Start_Time < @End_Time AND c.End_Time > @Start_Time)                          
             AND u.PU_Id = @PU_Id
           WHERE u.Start_Time < @End_Time AND ( u.End_Time > @Start_Time OR u.End_Time Is NULL ) AND u.PU_Id = @PU_Id 
      END
    Else --@AcknowledgedOnly >0
      BEGIN
        INSERT INTO #TempUDE (UDE_Id, UDE_Desc, Start_Time, End_Time, Duration, Event_Subtype_Id, PU_Id, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Crew_Desc, Shift_Desc, Ack_By, Ack_On, Research_User_Id, Research_Status_Id, Modified_On, Research_Open_Date, Research_Close_Date, Comment_Id, Cause_Comment_Id, Action_Comment_Id, Research_Comment_Id)
          SELECT DISTINCT
                 u.UDE_Id, u.UDE_Desc
               , [Start_Time] = Case When u.Start_Time >= u.Start_Time Then u.Start_Time Else u.Start_Time End
               , [End_Time]   = Case When u.End_Time Is NULL Then u.End_Time
                                     When u.End_Time <= u.End_Time Then u.End_Time Else u.End_Time 
                                End
               , u.Duration, u.Event_Subtype_Id, u.PU_Id, u.Cause1, u.Cause2, u.Cause3, u.Cause4, u.Action1, u.Action2, u.Action3, u.Action4, c.Crew_Desc, c.Shift_Desc, u.Ack_By, u.Ack_On, u.Research_User_Id, u.Research_Status_Id, u.Modified_On, u.Research_Open_Date, u.Research_Close_Date, u.Comment_Id, u.Cause_Comment_Id, u.Action_Comment_Id, u.Research_Comment_Id
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
        INSERT INTO #TempUDE (UDE_Id, UDE_Desc, Start_Time, End_Time, Duration, Event_Subtype_Id, PU_Id, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Crew_Desc, Shift_Desc, Ack_By, Ack_On, Research_User_Id, Research_Status_Id, Modified_On, Research_Open_Date, Research_Close_Date, Comment_Id, Cause_Comment_Id, Action_Comment_Id, Research_Comment_Id)
          SELECT DISTINCT
                 u.UDE_Id, u.UDE_Desc
               , [Start_Time] = Case When u.Start_Time >= u.Start_Time Then u.Start_Time Else u.Start_Time End
               , [End_Time]   = Case When u.End_Time Is NULL Then u.End_Time
                                     When u.End_Time <= u.End_Time Then u.End_Time Else u.End_Time 
                                End
               , u.Duration, u.Event_Subtype_Id, u.PU_Id, u.Cause1, u.Cause2, u.Cause3, u.Cause4, u.Action1, u.Action2, u.Action3, u.Action4, c.Crew_Desc, c.Shift_Desc, u.Ack_By, u.Ack_On, u.Research_User_Id, u.Research_Status_Id, u.Modified_On, u.Research_Open_Date, u.Research_Close_Date, u.Comment_Id, u.Cause_Comment_Id, u.Action_Comment_Id, u.Research_Comment_Id
            FROM User_Defined_Events u
            JOIN Prod_Units pu ON (pu.PU_Id = u.PU_Id AND pu.PU_Id <> 0)  
            JOIN Crew_Schedule c ON c.PU_Id = u.PU_Id AND c.Crew_Desc = @Crew_Desc AND c.Shift_Desc = @Shift_Desc
             AND u.Start_Time < c.End_Time AND ( u.End_Time > c.Start_Time OR u.End_Time Is NULL ) AND (c.Start_Time < @End_Time AND c.End_Time > @Start_Time) 
           WHERE u.Start_Time < @End_Time AND ( u.End_Time > @Start_Time OR u.End_Time Is NULL )
      END
    Else --@AcknowledgedOnly > 0
      BEGIN
        INSERT INTO #TempUDE (UDE_Id, UDE_Desc, Start_Time, End_Time, Duration, Event_Subtype_Id, PU_Id, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Crew_Desc, Shift_Desc, Ack_By, Ack_On, Research_User_Id, Research_Status_Id, Modified_On, Research_Open_Date, Research_Close_Date, Comment_Id, Cause_Comment_Id, Action_Comment_Id, Research_Comment_Id)
          SELECT DISTINCT
                 u.UDE_Id, u.UDE_Desc
               , [Start_Time] = Case When u.Start_Time >= u.Start_Time Then u.Start_Time Else u.Start_Time End
               , [End_Time]   = Case When u.End_Time Is NULL Then u.End_Time
                                     When u.End_Time <= u.End_Time Then u.End_Time Else u.End_Time 
                                End
               , u.Duration, u.Event_Subtype_Id, u.PU_Id, u.Cause1, u.Cause2, u.Cause3, u.Cause4, u.Action1, u.Action2, u.Action3, u.Action4, c.Crew_Desc, c.Shift_Desc, u.Ack_By, u.Ack_On, u.Research_User_Id, u.Research_Status_Id, u.Modified_On, u.Research_Open_Date, u.Research_Close_Date, u.Comment_Id, u.Cause_Comment_Id, u.Action_Comment_Id, u.Research_Comment_Id
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
        INSERT INTO #TempUDE (UDE_Id, UDE_Desc, Start_Time, End_Time, Duration, Event_Subtype_Id, PU_Id, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Crew_Desc, Shift_Desc, Ack_By, Ack_On, Research_User_Id, Research_Status_Id, Modified_On, Research_Open_Date, Research_Close_Date, Comment_Id, Cause_Comment_Id, Action_Comment_Id, Research_Comment_Id)
          SELECT DISTINCT
                 u.UDE_Id, u.UDE_Desc
               , [Start_Time] = Case When u.Start_Time >= u.Start_Time Then u.Start_Time Else u.Start_Time End
               , [End_Time]   = Case When u.End_Time Is NULL Then u.End_Time
                                     When u.End_Time <= u.End_Time Then u.End_Time Else u.End_Time 
                                End
               , u.Duration, u.Event_Subtype_Id, u.PU_Id, u.Cause1, u.Cause2, u.Cause3, u.Cause4, u.Action1, u.Action2, u.Action3, u.Action4, c.Crew_Desc, c.Shift_Desc, u.Ack_By, u.Ack_On, u.Research_User_Id, u.Research_Status_Id, u.Modified_On, u.Research_Open_Date, u.Research_Close_Date, u.Comment_Id, u.Cause_Comment_Id, u.Action_Comment_Id, u.Research_Comment_Id
            FROM User_Defined_Events u
            JOIN Prod_Units pu ON (pu.PU_Id = u.PU_Id AND pu.PU_Id <> 0)  
            JOIN Crew_Schedule c ON c.PU_Id = u.PU_Id AND c.Crew_Desc = @Crew_Desc AND c.Shift_Desc = @Shift_Desc
             AND u.Start_Time < c.End_Time AND ( u.End_Time > c.Start_Time OR u.End_Time Is NULL ) AND (c.Start_Time < @End_Time AND c.End_Time > @Start_Time)                          
             AND u.PU_Id = @PU_Id
           WHERE u.Start_Time < @End_Time AND ( u.End_Time > @Start_Time OR u.End_Time Is NULL ) AND u.PU_Id = @PU_Id 
      END
    Else --@AcknowledgedOnly > 0
      BEGIN
        INSERT INTO #TempUDE (UDE_Id, UDE_Desc, Start_Time, End_Time, Duration, Event_Subtype_Id, PU_Id, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Crew_Desc, Shift_Desc, Ack_By, Ack_On, Research_User_Id, Research_Status_Id, Modified_On, Research_Open_Date, Research_Close_Date, Comment_Id, Cause_Comment_Id, Action_Comment_Id, Research_Comment_Id)
          SELECT DISTINCT
                 u.UDE_Id, u.UDE_Desc
               , [Start_Time] = Case When u.Start_Time >= u.Start_Time Then u.Start_Time Else u.Start_Time End
               , [End_Time]   = Case When u.End_Time Is NULL Then u.End_Time
                                     When u.End_Time <= u.End_Time Then u.End_Time Else u.End_Time 
                                End
               , u.Duration, u.Event_Subtype_Id, u.PU_Id, u.Cause1, u.Cause2, u.Cause3, u.Cause4, u.Action1, u.Action2, u.Action3, u.Action4, c.Crew_Desc, c.Shift_Desc, u.Ack_By, u.Ack_On, u.Research_User_Id, u.Research_Status_Id, u.Modified_On, u.Research_Open_Date, u.Research_Close_Date, u.Comment_Id, u.Cause_Comment_Id, u.Action_Comment_Id, u.Research_Comment_Id
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
-- --------------------------------------------------
-- RETURN DATA
-- --------------------------------------------------
  If @TimeSort = 1
    BEGIN
 	   SELECT u.UDE_Id
               , u.UDE_Desc
               , u.Start_Time
               , u.End_Time
               , u.Duration 
               , Location = pu.PU_Desc
               , [Event_SubType] = Case When u.Event_Subtype_Id Is NULL     Then @Unspecified Else es.Event_Subtype_Desc End
               , Reason1  = Case When u.R1_Id Is NULL                       Then @Unspecified Else R1.Event_Reason_Name End
               , Reason2  = Case When u.R2_Id Is NULL                       Then @Unspecified Else R2.Event_Reason_Name End
               , Reason3  = Case When u.R3_Id Is NULL                       Then @Unspecified Else R3.Event_Reason_Name End
               , Reason4  = Case When u.R4_Id Is NULL                       Then @Unspecified Else R4.Event_Reason_Name End
               , Action1  = Case When u.A1_Id Is NULL                       Then @Unspecified Else A1.Event_Reason_Name End
               , Action2  = Case When u.A2_Id Is NULL                       Then @Unspecified Else A2.Event_Reason_Name End
               , Action3  = Case When u.A3_Id Is NULL                       Then @Unspecified Else A3.Event_Reason_Name End
               , Action4  = Case When u.A4_Id Is NULL                       Then @Unspecified Else A4.Event_Reason_Name End
               , [Research_Status] = Case When u.Research_Status_Id Is NULL Then @Unspecified Else r.Research_Status_Desc End
               , u.Crew_Desc
               , u.Shift_Desc
               , [Ack_By_User] = usr.Username
               , u.Ack_On
               , [Research_User] = usr2.Username
               , u.Modified_On
               , u.Research_Open_Date
               , u.Research_Close_Date
               , u.Comment_Id          
 	        , u.Cause_Comment_Id
               , u.Action_Comment_Id
               , u.Research_Comment_Id
            FROM #TempUDE u
          LEFT OUTER JOIN Prod_Units pu ON (pu.PU_Id = u.PU_Id)
          LEFT OUTER JOIN Event_Subtypes es ON es.Event_Subtype_Id = u.Event_Subtype_Id
          LEFT OUTER JOIN Event_Reasons R1 ON (R1.Event_Reason_Id = u.R1_Id)
          LEFT OUTER JOIN Event_ReasONs R2 ON (R2.Event_Reason_Id = u.R2_Id)
          LEFT OUTER JOIN Event_Reasons R3 ON (R3.Event_Reason_Id = u.R3_Id)
          LEFT OUTER JOIN Event_Reasons R4 ON (R4.Event_Reason_Id = u.R4_Id)
          LEFT OUTER JOIN Event_Reasons A1 ON (A1.Event_Reason_Id = u.A1_Id)
          LEFT OUTER JOIN Event_Reasons A2 ON (A2.Event_Reason_Id = u.A2_Id)
          LEFT OUTER JOIN Event_Reasons A3 ON (A3.Event_Reason_Id = u.A3_Id)
          LEFT OUTER JOIN Event_Reasons A4 ON (A4.Event_Reason_Id = u.A4_Id)
          LEFT OUTER JOIN Research_Status r ON r.Research_Status_Id = u.Research_Status_Id
          LEFT OUTER JOIN Users usr ON usr.User_Id = u.Ack_By
          LEFT OUTER JOIN Users usr2 ON usr2.User_Id = u.Research_User_Id
        ORDER BY u.Start_Time ASC
      END
  Else   -- Descending
    BEGIN
 	   SELECT u.UDE_Id
               , u.UDE_Desc
               , u.Start_Time
               , u.End_Time
               , u.Duration 
               , Location = pu.PU_Desc
               , [Event_SubType] = Case When u.Event_Subtype_Id Is NULL     Then @Unspecified Else es.Event_Subtype_Desc End
               , Reason1  = Case When u.R1_Id Is NULL                       Then @Unspecified Else R1.Event_Reason_Name End
               , Reason2  = Case When u.R2_Id Is NULL                       Then @Unspecified Else R2.Event_Reason_Name End
               , Reason3  = Case When u.R3_Id Is NULL                       Then @Unspecified Else R3.Event_Reason_Name End
               , Reason4  = Case When u.R4_Id Is NULL                       Then @Unspecified Else R4.Event_Reason_Name End
               , Action1  = Case When u.A1_Id Is NULL                       Then @Unspecified Else A1.Event_Reason_Name End
               , Action2  = Case When u.A2_Id Is NULL                       Then @Unspecified Else A2.Event_Reason_Name End
               , Action3  = Case When u.A3_Id Is NULL                       Then @Unspecified Else A3.Event_Reason_Name End
               , Action4  = Case When u.A4_Id Is NULL                       Then @Unspecified Else A4.Event_Reason_Name End
               , [Research_Status] = Case When u.Research_Status_Id Is NULL Then @Unspecified Else r.Research_Status_Desc End
               , u.Crew_Desc
               , u.Shift_Desc
               , [Ack_By_User] = usr.Username
               , u.Ack_On
               , [Research_User] = usr2.Username
               , u.Modified_On
               , u.Research_Open_Date
               , u.Research_Close_Date
               , u.Comment_Id          
 	        , u.Cause_Comment_Id
               , u.Action_Comment_Id
               , u.Research_Comment_Id
            FROM #TempUDE u
          LEFT OUTER JOIN Prod_Units pu ON (pu.PU_Id = u.PU_Id)
          LEFT OUTER JOIN Event_Subtypes es ON es.Event_Subtype_Id = u.Event_Subtype_Id
          LEFT OUTER JOIN Event_Reasons R1 ON (R1.Event_Reason_Id = u.R1_Id)
          LEFT OUTER JOIN Event_ReasONs R2 ON (R2.Event_Reason_Id = u.R2_Id)
          LEFT OUTER JOIN Event_Reasons R3 ON (R3.Event_Reason_Id = u.R3_Id)
          LEFT OUTER JOIN Event_Reasons R4 ON (R4.Event_Reason_Id = u.R4_Id)
          LEFT OUTER JOIN Event_Reasons A1 ON (A1.Event_Reason_Id = u.A1_Id)
          LEFT OUTER JOIN Event_Reasons A2 ON (A2.Event_Reason_Id = u.A2_Id)
          LEFT OUTER JOIN Event_Reasons A3 ON (A3.Event_Reason_Id = u.A3_Id)
          LEFT OUTER JOIN Event_Reasons A4 ON (A4.Event_Reason_Id = u.A4_Id)
          LEFT OUTER JOIN Research_Status r ON r.Research_Status_Id = u.Research_Status_Id
          LEFT OUTER JOIN Users usr ON usr.User_Id = u.Ack_By
          LEFT OUTER JOIN Users usr2 ON usr2.User_Id = u.Research_User_Id
        ORDER BY u.Start_Time DESC
      END
  --EndIf ToOrder...
  GOTO DROP_TEMP_TABLES
DROP_TEMP_TABLES:
  DROP TABLE #TempUDE
--
--DELETE FROM User_Connections Where SPID = @@SPID and User_Id = @UserId and Language_Id = @LangId

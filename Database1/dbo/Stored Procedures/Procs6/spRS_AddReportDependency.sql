CREATE PROCEDURE dbo.spRS_AddReportDependency
@Table int,
@Type int,
@Id int,
@Value varchar(255)
 AS
Declare @Exists int
If @Table = 1 -- Report Type Dependency
  Begin
    Select @Exists = RTD_Id
    From Report_Type_Dependencies
    Where Value = @Value
    And Report_Type_Id = @Id
    And RDT_Id = @Type
    If @Exists Is Null
      Begin
        Insert Into Report_Type_Dependencies(Report_Type_Id, RDT_Id, Value)
        Values(@Id, @Type, @Value)
        If @@Error <> 0 
 	   Return (1) -- Error
 	 Else
 	   Return (0) -- OK
      End
    Else
      Return (2) -- This entry exists
  End
Else 	  	 -- Report Web Page Dependency
  Begin
    Select @Exists = RWD_Id
    From Report_WebPage_Dependencies
    Where Value = @Value
    And RWP_Id = @Id
    And RDT_Id = @Type
    If @Exists Is Null
      Begin
        Insert Into Report_WebPage_Dependencies(RWP_Id, RDT_Id, Value)
 	 Values(@Id, @Type, @Value)
 	 If @@Error <> 0
          Return (1) -- Error
        Else
          Return (0) -- OK
      End
    Else
      Return (2) -- This entry exists
  End

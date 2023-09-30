CREATE TABLE [dbo].[Dashboard_Reports] (
    [Dashboard_Report_ID]                INT            IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Dashboard_Report_Ad_Hoc_Flag]       BIT            NOT NULL,
    [Dashboard_Report_Allow_Minimize]    INT            NOT NULL,
    [Dashboard_Report_Allow_Remove]      INT            NOT NULL,
    [Dashboard_Report_Cache_Code]        INT            NOT NULL,
    [Dashboard_Report_Cache_Timeout]     INT            NOT NULL,
    [Dashboard_Report_Column]            INT            NOT NULL,
    [Dashboard_Report_Column_Position]   INT            NOT NULL,
    [Dashboard_Report_Create_Date]       DATETIME       NULL,
    [Dashboard_Report_Description]       VARCHAR (4000) NULL,
    [Dashboard_Report_Detail_Link]       VARCHAR (500)  NULL,
    [Dashboard_Report_Expanded]          INT            NOT NULL,
    [Dashboard_Report_Has_Frame]         INT            NOT NULL,
    [Dashboard_Report_Help_Link]         VARCHAR (500)  NULL,
    [dashboard_report_name]              VARCHAR (100)  CONSTRAINT [DF__dashboard__dashb__0B486CA8] DEFAULT ('Dashboard_Report') NOT NULL,
    [Dashboard_Report_Number_Hits]       INT            NOT NULL,
    [Dashboard_Report_Security_Group_ID] INT            NULL,
    [Dashboard_Report_Server]            VARCHAR (100)  NOT NULL,
    [Dashboard_Report_Version_Count]     INT            NOT NULL,
    [Dashboard_Session_ID]               INT            NULL,
    [Dashboard_Template_ID]              INT            NOT NULL,
    [version]                            INT            CONSTRAINT [DF__dashboard__versi__407B4EF6] DEFAULT ((0)) NULL,
    CONSTRAINT [PK_Dashboard_Reports] PRIMARY KEY NONCLUSTERED ([Dashboard_Report_ID] ASC)
);


GO
CREATE UNIQUE CLUSTERED INDEX [IX_Dashboard_Reports]
    ON [dbo].[Dashboard_Reports]([Dashboard_Report_ID] ASC);


GO
CREATE TRIGGER dbo.Gallery_Delete_Trigger
  ON dbo.Dashboard_Reports
  FOR DELETE
  AS
Declare
  @Report_Server varchar(100),
  @Ad_Hoc bit
DECLARE Report_Cursor CURSOR
  FOR select distinct(Dashboard_Report_Server), Dashboard_Report_Ad_Hoc_Flag from Deleted
  FOR READ ONLY
OPEN Report_Cursor
Fetch_Next_Delete:
  Fetch Next From Report_Cursor INTO   @Report_Server, @Ad_Hoc
  If @@FETCH_STATUS = 0
    Begin
 	 if (@Ad_Hoc = 0)
 	 begin
 	  	 exec spDBR_Store_Gallery_Server @Report_Server
 	  	 update dashboard_gallery_Generator_Servers set dirtybit = 1 where server = @Report_Server
 	 end
      GOTO Fetch_Next_Delete
    End
DEALLOCATE Report_Cursor

GO
CREATE TRIGGER dbo.Gallery_Insert_Trigger
  ON dbo.Dashboard_Reports
  FOR INSERT
  AS
Declare
  @Report_Server varchar(100),
  @Ad_Hoc bit
DECLARE Report_Cursor CURSOR
  FOR select distinct(Dashboard_Report_Server), Dashboard_Report_Ad_Hoc_Flag from Inserted
  FOR READ ONLY
OPEN Report_Cursor
Fetch_Next_Insert:
  Fetch Next From Report_Cursor INTO   @Report_Server, @Ad_Hoc
  If @@FETCH_STATUS = 0
    Begin
 	 if (@Ad_Hoc = 0)
 	 begin
 	  	 exec spDBR_Store_Gallery_Server @Report_Server
 	  	 update dashboard_gallery_Generator_Servers set dirtybit = 1 where server = @Report_Server
 	 end
      GOTO Fetch_Next_Insert
    End
DEALLOCATE Report_Cursor

GO
CREATE TRIGGER dbo.Gallery_Update_Trigger
  ON dbo.Dashboard_Reports
  FOR UPDATE
  AS
Declare
  @Report_Server varchar(100),
  @Ad_Hoc bit
DECLARE Report_Cursor CURSOR
  FOR select distinct(Dashboard_Report_Server), Dashboard_Report_Ad_Hoc_Flag from Inserted
  FOR READ ONLY
OPEN Report_Cursor
Fetch_Next_Update:
  Fetch Next From Report_Cursor INTO   @Report_Server, @Ad_Hoc
  If @@FETCH_STATUS = 0
    Begin
 	 if (@Ad_Hoc = 0)
 	 begin
 	  	 exec spDBR_Store_Gallery_Server @Report_Server
 	  	 update dashboard_gallery_Generator_Servers set dirtybit = 1 where server = @Report_Server
 	 end
      GOTO Fetch_Next_Update
    End
DEALLOCATE Report_Cursor

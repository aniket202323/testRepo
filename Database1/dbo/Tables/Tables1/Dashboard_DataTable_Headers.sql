CREATE TABLE [dbo].[Dashboard_DataTable_Headers] (
    [Dashboard_DataTable_Header_ID]    INT           IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Dashboard_DataTable_Column]       INT           NOT NULL,
    [Dashboard_DataTable_Column_SP]    VARCHAR (100) NULL,
    [Dashboard_DataTable_Header]       VARCHAR (50)  NULL,
    [Dashboard_DataTable_Presentation] BIT           NULL,
    [Dashboard_Parameter_Type_ID]      INT           NOT NULL,
    CONSTRAINT [PK_Dashboard_DataTable_Headers] PRIMARY KEY NONCLUSTERED ([Dashboard_DataTable_Header_ID] ASC, [Dashboard_Parameter_Type_ID] ASC, [Dashboard_DataTable_Column] ASC)
);


GO
CREATE UNIQUE CLUSTERED INDEX [IX_Dashboard_DataTable_Headers]
    ON [dbo].[Dashboard_DataTable_Headers]([Dashboard_DataTable_Header_ID] ASC);


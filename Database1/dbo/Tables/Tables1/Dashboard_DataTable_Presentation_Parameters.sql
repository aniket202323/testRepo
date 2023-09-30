CREATE TABLE [dbo].[Dashboard_DataTable_Presentation_Parameters] (
    [Dashboard_DataTable_Presentation_Parameter_ID]    INT IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Dashboard_DataTable_Header_ID]                    INT NOT NULL,
    [Dashboard_DataTable_Presentation_Parameter_Input] INT NOT NULL,
    [Dashboard_DataTable_Presentation_Parameter_Order] INT NOT NULL,
    CONSTRAINT [PK_Dashboard_DataTable_Presentation_Parameters] PRIMARY KEY CLUSTERED ([Dashboard_DataTable_Presentation_Parameter_ID] ASC)
);


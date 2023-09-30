CREATE TABLE [dbo].[Dashboard_Parameter_Data_Types] (
    [Dashboard_Parameter_Data_Type_ID] INT           IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Dashboard_Parameter_Data_Type]    VARCHAR (100) NULL,
    CONSTRAINT [PK_Dashboard_Parameter_Data_Types] PRIMARY KEY NONCLUSTERED ([Dashboard_Parameter_Data_Type_ID] ASC)
);


GO
CREATE UNIQUE CLUSTERED INDEX [IX_Dashboard_Parameter_Data_Types]
    ON [dbo].[Dashboard_Parameter_Data_Types]([Dashboard_Parameter_Data_Type_ID] ASC);


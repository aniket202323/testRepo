CREATE TABLE [dbo].[Report_Printers] (
    [Printer_Id]   INT          IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Printer_Name] VARCHAR (50) NOT NULL,
    CONSTRAINT [PK_Report_Printers] PRIMARY KEY NONCLUSTERED ([Printer_Id] ASC)
);


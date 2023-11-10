using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace eCIL_DataLayer
{
    public class ValidatedTask
    {

        #region Variables

        private string fL1;
        private string fL2;
        private string fL3;
        private string fL4;
        private string eCIL_Criteria;
        private string eCIL_Duration;
        private string eCIL_FixedFreq;
        private string eCIL_Hazard;
        private string eCIL_LongTaskName;
        private string eCIL_TaskName;
        private string eCIL_Lubrication;
        private string eCIL_Method;
        private string eCIL_NbrItems;
        private string eCIL_NbrPeople;
        private string eCIL_PPE;
        private string eCIL_Task_Action;
        private string eCIL_Active;
        private string eCIL_Window;
        private string eCIL_Frequency;
        private string eCIL_TaskType;
        private string eCIL_TestTime;
        private string eCIL_Tools;
        private string eCIL_VMID;
        private string eCIL_TaskLocation;
        private string eCIL_ScheduleScope;
        private string eCIL_LastCompletionDate;
        private string eCIL_FirstEffectiveDate;
        private string eCIL_LineVersion;
        private string eCIL_ModuleFeatureVersion;
        private string eCIL_TaskId;
        private string eCIL_Module;
        private string eCIL_documentDesc1;
        private string eCIL_documentLink1;
        private string eCIL_documentDesc2;
        private string eCIL_documentLink2;
        private string eCIL_documentDesc3;
        private string eCIL_documentLink3;
        private string eCIL_documentDesc4;
        private string eCIL_documentLink4;
        private string eCIL_documentDesc5;
        private string eCIL_documentLink5;
        private string eCIL_HSEFlag;
        private string eCIL_FreqType;
        private string eCIL_ShiftOffset;
        private string eCIL_autopostpone;
        #endregion


        #region Properties

        public string FL1 { get => fL1; set => fL1 = value; }
        public string FL2 { get => fL2; set => fL2 = value; }
        public string FL3 { get => fL3; set => fL3 = value; }
        public string FL4 { get => fL4; set => fL4 = value; }
        public string ECILCriteria { get => eCIL_Criteria; set => eCIL_Criteria = value; }
        public string ECILDuration { get => eCIL_Duration; set => eCIL_Duration = value; }
        public string ECILFixedFreq { get => eCIL_FixedFreq; set => eCIL_FixedFreq = value; }
        public string ECILHazard { get => eCIL_Hazard; set => eCIL_Hazard = value; }
        public string ECILLongTaskName { get => eCIL_LongTaskName; set => eCIL_LongTaskName = value; }
        public string ECILTaskName { get => eCIL_TaskName; set => eCIL_TaskName = value; }
        public string ECILLubrication { get => eCIL_Lubrication; set => eCIL_Lubrication = value; }
        public string ECILMethod { get => eCIL_Method; set => eCIL_Method = value; }
        public string ECILNbrItems { get => eCIL_NbrItems; set => eCIL_NbrItems = value; }
        public string ECILNbrPeople { get => eCIL_NbrPeople; set => eCIL_NbrPeople = value; }
        public string ECILPPE { get => eCIL_PPE; set => eCIL_PPE = value; }
        public string ECILTaskAction { get => eCIL_Task_Action; set => eCIL_Task_Action = value; }
        public string ECILActive { get => eCIL_Active; set => eCIL_Active = value; }
        public string ECILWindow { get => eCIL_Window; set => eCIL_Window = value; }
        public string ECILFrequency { get => eCIL_Frequency; set => eCIL_Frequency = value; }
        public string ECILTaskType { get => eCIL_TaskType; set => eCIL_TaskType = value; }
        public string ECILTestTime1 { get => eCIL_TestTime; set => eCIL_TestTime = value; }
        public string ECILTools1 { get => eCIL_Tools; set => eCIL_Tools = value; }
        public string ECILVMID { get => eCIL_VMID; set => eCIL_VMID = value; }
        public string ECILTaskLocation { get => eCIL_TaskLocation; set => eCIL_TaskLocation = value; }
        public string ECILScheduleScope { get => eCIL_ScheduleScope; set => eCIL_ScheduleScope = value; }
        public string ECILLastCompletionDate { get => eCIL_LastCompletionDate; set => eCIL_LastCompletionDate = value; }
        public string ECILFirstEffectiveDate { get => eCIL_FirstEffectiveDate; set => eCIL_FirstEffectiveDate = value; }
        public string ECILLineVersion { get => eCIL_LineVersion; set => eCIL_LineVersion = value; }
        public string ECILModuleFeatureVersion { get => eCIL_ModuleFeatureVersion; set => eCIL_ModuleFeatureVersion = value; }
        public string ECILTaskId { get => eCIL_TaskId; set => eCIL_TaskId = value; }
        public string ECILModule { get => eCIL_Module; set => eCIL_Module = value; }
        public string ECILDocumentDesc1 { get => eCIL_documentDesc1; set => eCIL_documentDesc1 = value; }
        public string ECILDocumentLink1 { get => eCIL_documentLink1; set => eCIL_documentLink1 = value; }
        public string ECILDocumentDesc2 { get => eCIL_documentDesc2; set => eCIL_documentDesc2 = value; }
        public string ECILDocumentLink2 { get => eCIL_documentLink2; set => eCIL_documentLink2 = value; }
        public string ECILDocumentDesc3 { get => eCIL_documentDesc3; set => eCIL_documentDesc3 = value; }
        public string ECILDocumentLink3 { get => eCIL_documentLink3; set => eCIL_documentLink3 = value; }
        public string ECILDocumentDesc4 { get => eCIL_documentDesc4; set => eCIL_documentDesc4 = value; }
        public string ECILDocumentLink4 { get => eCIL_documentLink4; set => eCIL_documentLink4 = value; }
        public string ECILDocumentDesc5 { get => eCIL_documentDesc5; set => eCIL_documentDesc5 = value; }
        public string ECILDocumentLink5 { get => eCIL_documentLink5; set => eCIL_documentLink5 = value; }
        public string ECILHSEFlag { get => eCIL_HSEFlag; set => eCIL_HSEFlag = value; }
        public string ECILFreqType { get => eCIL_FreqType; set => eCIL_FreqType = value; }
        public string ECILShiftOffset { get => eCIL_ShiftOffset; set => eCIL_ShiftOffset = value; }
        public string ECILAutopostpone { get => eCIL_autopostpone; set => eCIL_autopostpone = value; }

        #endregion

    }
}

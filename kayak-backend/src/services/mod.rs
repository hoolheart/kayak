//! 服务层模块
//!
//! 包含业务逻辑服务

pub mod device;
pub mod experiment_query;
pub mod hdf5;
pub mod point;
pub mod point_history;
pub mod timeseries_buffer;
pub mod user;
pub mod user_repo_adapter;
pub mod workbench;

pub use device::{
    CreateDeviceEntity, DeviceDto, DeviceError, DeviceService, DeviceServiceImpl, PagedDeviceDto,
    UpdateDeviceEntity,
};
pub use experiment_query::{
    DataFileError, DataFileInfo, ExperimentFilter, ExperimentQueryError, ExperimentQueryService,
    PointHistoryError, TimeRange,
};
pub use hdf5::{
    CompressionInfo,
    CompressionType,
    DatasetType,
    Hdf5Dataset,
    Hdf5Error,
    Hdf5File,
    Hdf5Group,
    Hdf5Service,
    Hdf5ServiceImpl,
    IntegrityReport,
    PathStrategy,
    PathStrategyConfig,
};
pub use point::{
    CreatePointEntity, PagedPointDto, PointDto, PointError, PointService, PointServiceImpl,
    PointValueDto, UpdatePointEntity,
};
pub use point_history::{Hdf5PointHistoryRepository, PointHistoryRepository};
pub use user::{
    ChangePasswordRequest, UpdateUserEntity, UpdateUserRequest, UserDto, UserError, UserService,
    UserServiceImpl,
};
pub use user_repo_adapter::UserServiceRepositoryAdapter;
pub use workbench::{
    PagedWorkbenchDto, WorkbenchDto, WorkbenchError, WorkbenchService, WorkbenchServiceImpl,
};

/**
 * Copyright (c) 2022-2024 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import certManagerModel from '../model/CertMangerModel';
import { CMModelErrorCode, CMModelOptType, CertAlgorithm } from '../model/CertMangerModel';
import { CertAbstractVo } from '../model/CertManagerVo/CertAbstractVo';
import { CertInfoVo } from '../model/CertManagerVo/CertInfoVo';
import Logger from '../common/util/Logger';
import CertManager from '@ohos.security.certManager';

const logger: Logger = new Logger('CmShowSysCaPresenter');

export default class CmShowSysCaPresenter {
  private static sInstance: CmShowSysCaPresenter;
  public certList: CertAbstractVo[] = [];
  public certInfo: CertInfoVo = new CertInfoVo('', '', false, '', '', '', '', '', '',
    new Uint8Array(), new Map(), new Map(), new Map());
  public intlCertList: CertAbstractVo[] = [];
  public smCertList: CertAbstractVo[] = [];
  public certStoreVersion: string = '';
  public smCertStoreVersion: string = '';

  public static getInstance(): CmShowSysCaPresenter {
    if (CmShowSysCaPresenter.sInstance == null) {
      CmShowSysCaPresenter.sInstance = new CmShowSysCaPresenter();
    }
    return CmShowSysCaPresenter.sInstance;
  }

  onAboutToAppear(): void {
    this.updateSystemTrustedCertificateList();
  }

  aboutToDisappear(): void {
    this.certList = [];
    this.intlCertList = [];
    this.smCertList = [];
    this.certStoreVersion = '';
    this.smCertStoreVersion = '';
    this.certInfo = new CertInfoVo('', '', false, '', '', '', '', '', '',
      new Uint8Array(), new Map(), new Map(), new Map());
  }

  updateSystemTrustedCertificateList(onComplete?: () => void): void {
    certManagerModel.getSystemTrustedCertificateListByAlg(CertAlgorithm.INTERNATIONAL,
      (errCode: CMModelErrorCode, certList: CertAbstractVo[], certStoreInfo?: CertManager.CertStoreInfo) => {
      if (errCode === CMModelErrorCode.CM_MODEL_ERROR_SUCCESS) {
        this.intlCertList = this.sortCertList(certList);
        this.certStoreVersion = certStoreInfo?.certStoreVersion ?? '';
      } else {
        logger.error('get intl system trusted ca list fail, errCode is ' + errCode);
        this.intlCertList = [];
        this.certStoreVersion = '';
      }
      this.getSmSystemTrustedCertificateList(onComplete);
    });
  }

  private getSmSystemTrustedCertificateList(onComplete?: () => void): void {
    certManagerModel.getSystemTrustedCertificateListByAlg(CertAlgorithm.SM,
      (errCode: CMModelErrorCode, certList: CertAbstractVo[], certStoreInfo?: CertManager.CertStoreInfo) => {
      if (errCode === CMModelErrorCode.CM_MODEL_ERROR_SUCCESS) {
        this.smCertList = this.sortCertList(certList);
        this.smCertStoreVersion = certStoreInfo?.smCertStoreVersion ?? '';
      } else {
        logger.error('get sm system trusted ca list fail, errCode is ' + errCode);
        this.smCertList = [];
        this.smCertStoreVersion = '';
      }
      if (onComplete !== undefined) {
        onComplete();
      }
    });
  }

  private sortCertList(certList: CertAbstractVo[]): CertAbstractVo[] {
    let sorted: CertAbstractVo[] = certList.slice();
    sorted.sort((certAbs: CertAbstractVo, certAbsOther: CertAbstractVo): number => {
      let certAlias: string = certAbs.certAlias;
      let certAliasOther: string = certAbsOther.certAlias;
      if (certAlias <= certAliasOther) {
        return -1;
      } else {
        return 1;
      }
    });
    return sorted;
  }

  getSystemTrustedCertificate(uri: string, callback: Function): void {
    certManagerModel.getCertOrCred(CMModelOptType.CM_MODEL_OPT_SYSTEM_CA, uri,
      (errCode: CMModelErrorCode, certInfo: CertInfoVo) => {
      if (errCode === CMModelErrorCode.CM_MODEL_ERROR_SUCCESS) {
        logger.info('getSystemTrustedCertificate success,errCode is ' + errCode);
        this.certInfo = certInfo;
        callback();
      } else {
        logger.error('getSystemTrustedCertificate fail,errCode is' + errCode);
        this.certInfo.clearCertInfoVo();
        callback();
      }
    });
  }

  setSystemCertificateStatus(uri: string, status: boolean, onComplete?: () => void): void {
    certManagerModel.setCertStatus(CMModelOptType.CM_MODEL_OPT_SYSTEM_CA, uri, status,
      (errCode: CMModelErrorCode) => {
      if (errCode === CMModelErrorCode.CM_MODEL_ERROR_SUCCESS) {
        logger.info('setSystemCertificateStatus success,errCode is' + errCode);
        this.updateSystemTrustedCertificateList(onComplete);
      } else {
        logger.error('setSystemCertificateStatus fail,errCode is' + errCode);
        if (onComplete !== undefined) {
          onComplete();
        }
      }
    });
  }
}
import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../../environments/environment';

export interface State {
  id: string;
  stateId: string;
  name: string;
  code: string;
  createdAt: string;
  updatedAt: string;
}

export interface Facility {
  id: string;
  facilityId: string;
  stateId: string;
  name: string;
  code: string;
  type: string;
  createdAt: string;
  updatedAt: string;
}

@Injectable({ providedIn: 'root' })
export class StateService {
  constructor(private http: HttpClient) {}

  getStates(): Observable<State[]> {
    return this.http.get<State[]>(`${environment.apiUrl}/admin/states`);
  }

  createState(data: { name: string; code: string }): Observable<State> {
    return this.http.post<State>(`${environment.apiUrl}/admin/states`, data);
  }

  updateState(id: string, data: { name: string; code: string }): Observable<State> {
    return this.http.put<State>(`${environment.apiUrl}/admin/states/${id}`, data);
  }

  deleteState(id: string): Observable<any> {
    return this.http.delete(`${environment.apiUrl}/admin/states/${id}`);
  }
}

@Injectable({ providedIn: 'root' })
export class FacilityService {
  constructor(private http: HttpClient) {}

  getFacilities(stateId: string): Observable<Facility[]> {
    return this.http.get<Facility[]>(`${environment.apiUrl}/admin/states/${stateId}/facilities`);
  }

  createFacility(stateId: string, data: { name: string; code: string; type: string }): Observable<Facility> {
    return this.http.post<Facility>(`${environment.apiUrl}/admin/states/${stateId}/facilities`, data);
  }

  updateFacility(stateId: string, facilityId: string, data: { name: string; code: string; type: string }): Observable<Facility> {
    return this.http.put<Facility>(`${environment.apiUrl}/admin/states/${stateId}/facilities/${facilityId}`, data);
  }

  deleteFacility(stateId: string, facilityId: string): Observable<any> {
    return this.http.delete(`${environment.apiUrl}/admin/states/${stateId}/facilities/${facilityId}`);
  }

  bulkUpload(stateId: string, facilities: { name: string; code: string; type: string }[]): Observable<any> {
    return this.http.post(`${environment.apiUrl}/admin/states/${stateId}/facilities/upload`, { facilities });
  }
}
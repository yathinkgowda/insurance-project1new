package com.project.staragile.insureme;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class PolicyService {

	@Autowired
	PolicyRepository policyRepository;

	public Policy CreatePolicy() {

		Policy policy = generateDummyPolicy();

		return policyRepository.save(policy);

	}

	public Policy updatePolicy() {

		return null;
	}

	public String deletePolicy(int policyId) {

		policyRepository.deleteById(policyId);
		return "Deleted Successfully";
	}

	public Policy searchPolicy() {

		return null;
	}

	public Policy generateDummyPolicy() {
		return new Policy(1, "Vikul", "Individual", 10000, "10-Sep-2021", "10-Sep-2022");
	}

	public Policy registerPolicy(Policy policy) {
		// TODO Auto-generated method stub
		return policyRepository.save(policy);
	}

	public Policy getPolicyDetails(int policyId) {
		// TODO Auto-generated method stub
		return policyRepository.findById(policyId).get();
	}
	
	public Policy updatePolicy(Policy pol, int policyId) {
		Policy pc = policyRepository.findById(policyId).get();
		pc.setPolicyHolderName(pol.getPolicyHolderName());
		pc.setPolicyPrice(pol.getPolicyPrice());
		pc.setPolicyType(pol.getPolicyType());
		pc.setPolicyStartDate(pol.getPolicyStartDate());
		pc.setPolicyEndDate(pol.getPolicyEndDate());

		//after updation save in db
		policyRepository.save(pc);

		return pc;
	}

}

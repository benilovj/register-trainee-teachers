Support Playbook
================

## Making data changes

If you're making a data change, try to include an `audit_comment` so that we can see why we did this. E.g

```
trainee.update(date_of_birth: <whatevs>, audit_comment: 'Update from the trainee via DQT')
```

## Changing training route

Sometimes support will ask a dev to update the training route. Here is an example for updating a route to `school_direct_salaried`.

```
trainee = Trainee.find_by(slug: "XXX")
manager = RouteDataManager.new(trainee: trainee)
manager.update_training_route!("school_direct_salaried")
```

A bunch of fields will be set to `nil`, see `RouteDataManager` class. Ask support to communicate with the user to update the Trainee record for the missing information.

## Unwithdrawing a withdrawn trainee

Sometimes support will ask a dev to unwithdraw a trainee which has been withdrawn in error. You can find the previous trainee state by running `trainee.audits` and comparing the numbers to the enum in `trainee.rb`.

Here is an examole of unwithdrawing a trainee without leaving an audit trail.

```ruby
trainee = Trainee.find_by(slug: "XXX")

trainee.without_auditing do
  trainee.update_columns(state: "XXX", withdraw_reason: nil, additional_withdraw_reason: nil, withdraw_date: nil)
end
```

## Error codes on DQT trainee jobs

Sometimes the different jobs that send trainee info to DQT (such as `Dqt::UpdateTraineeJob`,`Dqt::WithdrawTraineeJob` and `Dqt::RecommendForAwardJob` ) will produce an error. You can view these failed jobs in the Sidekiq UI. 

Sometimes a trainee will have both a failed update job, and a failed award job. In this case, make sure to re-run the update job first. If you run the award job first and then try to run the update job, the update will fail as the trainee will already have QTS (and therefore can no longer be updated on DQT's end).

There is also a handy DQT API that you can call, to see some useful information that DQT hold on their end. Call the following
where `t` is the trainee:

```
Dqt::Client.get("/v1/teachers/#{t.trn}?birthdate=#{t.date_of_birth.iso8601}")
```

This list is not exhaustive, but here are some common errors types that we see:

### 500 error

This is a cloud server error. You can usually just rerun these jobs and they'll succeed. If not, speak with DQT about the trainee.

### 404 error

This is triggered when DQT cannot find the trainee on their side.

```
status: 404, body: {"title":"Teacher with specified TRN not found","status":404,"errorCode":10001}
```

* This can happen when there is a mismatch between the date of birth that Register holds for the trainee vs what DQT holds (we send both TRN and DOB to DQT to match trainees)

* I've also seen this error come up when the trainee's TRN is inactive on the DQT side

Speak with the DQT team to work out if it's one of the above issues. Align the date of birth on both services and re-run the job.

### 400 error

This error means there is an unprocessable entry. This normally means there is some kind of validation error in the payload which will need to be investigated.

```
status: 400, body: {"title":"Teacher has no QTS record","status":400,"errorCode":10006}
```

* There might be a trainee state mismatch here between DQT and Register
* We've seen this error when a trainee has been withdrawn on DQT and awarded on Register
* We have some known examples of trainees like this so it's worth checking with our support team to see if there are existing comms about the trainee
* In this case you might need to check with the provider what the state of the record should be

```
status: 400, body: {"title":"Teacher has no incomplete ITT record","status":400,"errorCode":10005}
```
* If this error came from the award job, then the trainee might be stuck in recommended for award state
* If everything matches on DQT's side (trainee details, the provider) then you may be able to just award the trainee on Register's side
* If any doubt then check with the provider
* We've also seen this error on the withdraw job - cross-reference with DQT and check with provider if necessary to see what state the trainee should be in

```
“qualification.providerUkprn”:[“Organisation not found”]
```
* We send the UKPRN of the trainee's degree institution to DQT
* This error happens when DQT do not have a matching UKPRN on their end for the trainee's degree organisation
* Locate the institution_uuid for the failing trainee and look up the UKPRN in the DfE Reference Data gem repo
* Send the UKPRN and degree institution details over to DQT so they can add on their side and re-run the job

```
{"initialTeacherTraining.programmeType":["Teacher already has QTS/EYTS date"]}
```
* We've noticed there is likely a race condition sometimes causing this error
* When we run an award job, an update job is also kicked off
* We think that sometimes the award job succeeds before the update job, which causes this error on the update job
* Cross reference the trainee details on Register with the trainee details on DQT, you can use the DQT API for this - checking the trainee timeline on Register can also be helful
* If there are no differences, it is likely a race condition and you can delete the failed update job
* If there are differences, speak to DQT and maybe contact provider to see what needs updating
